<?php

namespace App\Services;

use App\Models\NotificationDispatchLog;
use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use Throwable;

class PushNotificationService
{
    public function __construct(
        private readonly FcmAccessTokenProvider $fcmAccessTokenProvider
    ) {}

    public function notifyUsers(
        array $recipientUserIds,
        string $title,
        string $message,
        string $module,
        string $eventType,
        ?int $senderUserId = null,
        array $context = []
    ): int {
        if ($recipientUserIds === []) {
            return 0;
        }

        $devices = UserDevice::query()
            ->whereIn('user_id', $recipientUserIds)
            ->get(['user_id', 'fcm_token'])
            ->map(fn(UserDevice $device) => [
                'user_id' => (int) $device->user_id,
                'fcm_token' => (string) $device->fcm_token,
            ])
            ->all();

        $result = $this->notifyDevices($devices, $title, $message, $module, $eventType, $senderUserId, $context);

        return $result['success_count'] + $result['queued_count'];
    }

    public function notifyDevices(
        array $devices,
        string $title,
        string $message,
        string $module,
        string $eventType,
        ?int $senderUserId = null,
        array $context = []
    ): array {
        $result = [
            'target_count' => count($devices),
            'success_count' => 0,
            'failed_count' => 0,
            'queued_count' => 0,
        ];

        if ($devices === []) {
            return $result;
        }

        $traceId = $this->traceId();
        $fcmEnabled = filter_var((string) config('services.fcm.enabled', false), FILTER_VALIDATE_BOOL);

        if (! $fcmEnabled) {
            return $this->queueAll($result, $devices, $title, $message, $module, $eventType, $senderUserId, $traceId, $context);
        }

        $auth = $this->fcmAccessTokenProvider->fetch();

        if ($auth === null || ! isset($auth['project_id'], $auth['token'])) {
            return $this->queueAll($result, $devices, $title, $message, $module, $eventType, $senderUserId, $traceId, $context);
        }

        $projectId = (string) $auth['project_id'];
        $accessToken = (string) $auth['token'];
        $endpoint = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

        $seenTokens = [];

        foreach ($devices as $device) {
            $recipientUserId = (int) $device['user_id'];
            $fcmToken = (string) $device['fcm_token'];

            $status = 'queued';
            $providerResponse = ['reason' => 'not_sent'];

            $isDuplicate = isset($seenTokens[$fcmToken]);

            if (isset($seenTokens[$fcmToken])) {
                $seenTokens[$fcmToken]['count']++;
                continue;
            }

            $seenTokens[$fcmToken] = ['count' => 1, 'result' => null];

            try {
                $httpResponse = Http::timeout(8)
                    ->withHeaders([
                        'Authorization' => 'Bearer ' . $accessToken,
                        'Content-Type' => 'application/json',
                    ])
                    ->post($endpoint, [
                        'message' => [
                            'token' => $fcmToken,
                            'notification' => [
                                'title' => $title,
                                'body' => $message,
                            ],
                            'data' => array_merge($context, [
                                'module' => $module,
                                'event_type' => $eventType,
                                'trace_id' => $traceId,
                            ]),
                            'android' => [
                                'notification' => [
                                    'channel_id' => 'high_importance_channel',
                                ],
                            ],
                        ],
                    ]);

                if ($httpResponse->successful()) {
                    $status = 'sent';
                    $providerResponse = ['http_status' => $httpResponse->status(), 'body' => $httpResponse->json()];
                } else {
                    $status = 'failed';
                    $providerResponse = ['http_status' => $httpResponse->status(), 'body' => $httpResponse->body()];

                    if ($this->isUnregistered($httpResponse->json())) {
                        UserDevice::query()->where('fcm_token', $fcmToken)->delete();
                        $providerResponse['token_revoked'] = true;
                    }
                }
            } catch (Throwable $throwable) {
                $status = 'failed';
                $providerResponse = ['error' => $throwable->getMessage()];
            }

            $seenTokens[$fcmToken]['result'] = [$status, $providerResponse, $recipientUserId];
        }

        foreach ($seenTokens as $fcmToken => $info) {
            if ($info['result'] === null) {
                continue;
            }
            [$status, $providerResponse, $recipientUserId] = $info['result'];

            NotificationDispatchLog::query()->create([
                'sender_user_id' => $senderUserId,
                'recipient_user_id' => $recipientUserId,
                'fcm_token' => $fcmToken,
                'module' => $module,
                'event_type' => $eventType,
                'title' => $title,
                'message' => $message,
                'context' => $context,
                'status' => $status,
                'provider' => 'fcm_v1',
                'trace_id' => $traceId,
                'provider_response' => $providerResponse,
            ]);

            if ($status === 'sent') {
                $result['success_count']++;
            } elseif ($status === 'failed') {
                $result['failed_count']++;
            } else {
                $result['queued_count']++;
            }
        }

        $result['target_count'] = count($seenTokens);

        $this->sendEmailNotifications(
            collect($seenTokens)->keys()->map(fn($t) => $t)->all(),
            $title, $message, $module, $eventType, $senderUserId, $traceId, $context
        );

        return $result;
    }

    public function deactivateUnregisteredToken(string $fcmToken): void
    {
        UserDevice::query()->where('fcm_token', $fcmToken)->delete();
    }

    private function isUnregistered(?array $body): bool
    {
        $errorCode = data_get($body, 'error.status');
        $fcmError = data_get($body, 'error.details.0.errorCode');

        return $errorCode === 'NOT_FOUND' || $fcmError === 'UNREGISTERED';
    }

    private function queueAll(
        array $result,
        array $devices,
        string $title,
        string $message,
        string $module,
        string $eventType,
        ?int $senderUserId,
        ?string $traceId,
        array $context
    ): array {
        foreach ($devices as $device) {
            NotificationDispatchLog::query()->create([
                'sender_user_id' => $senderUserId,
                'recipient_user_id' => (int) $device['user_id'],
                'fcm_token' => (string) $device['fcm_token'],
                'module' => $module,
                'event_type' => $eventType,
                'title' => $title,
                'message' => $message,
                'context' => $context,
                'status' => 'queued',
                'provider' => 'fcm',
                'trace_id' => $traceId,
                'provider_response' => ['reason' => 'fcm_not_configured'],
            ]);
            $result['queued_count']++;
        }

        $this->sendEmailNotifications(
            collect($devices)->pluck('user_id')->map(fn($id) => (int) $id)->unique()->values()->all(),
            $title, $message, $module, $eventType, $senderUserId, $traceId, $context
        );

        return $result;
    }

    private function sendEmailNotifications(
        array $recipientUserIds,
        string $title,
        string $message,
        string $module,
        string $eventType,
        ?int $senderUserId,
        ?string $traceId,
        array $context
    ): void {
        $emailEnabled = filter_var((string) config('services.notifications.email_enabled', false), FILTER_VALIDATE_BOOL);

        if (! $emailEnabled || $recipientUserIds === []) {
            return;
        }

        $recipients = User::query()
            ->whereIn('id', $recipientUserIds)
            ->whereNotNull('email')
            ->get(['id', 'email']);

        foreach ($recipients as $recipient) {
            $email = (string) $recipient->email;
            if ($email === '') {
                continue;
            }

            $status = 'sent';
            $providerResponse = ['channel' => 'smtp'];

            try {
                Mail::raw($message, function ($mail) use ($email, $title): void {
                    $mail->to($email)->subject($title);
                });
            } catch (Throwable $throwable) {
                $status = 'failed';
                $providerResponse = ['error' => $throwable->getMessage()];
            }

            NotificationDispatchLog::query()->create([
                'sender_user_id' => $senderUserId,
                'recipient_user_id' => (int) $recipient->id,
                'fcm_token' => $email,
                'module' => $module,
                'event_type' => $eventType,
                'title' => $title,
                'message' => $message,
                'context' => $context,
                'status' => $status,
                'provider' => 'email',
                'trace_id' => $traceId,
                'provider_response' => $providerResponse,
            ]);
        }
    }

    private function traceId(): ?string
    {
        $traceId = request()->attributes->get('trace_id') ?? request()->header('X-Trace-Id');
        return is_string($traceId) ? $traceId : null;
    }
}
