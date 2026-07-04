<?php

namespace App\Jobs;

use App\Models\NotificationDispatchLog;
use App\Models\ServiceApplication;
use App\Models\User;
use App\Services\PushNotificationService;
use Carbon\Carbon;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

class SendServiceFollowUpJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [60, 300, 900];

    public function __construct(
        public int $applicationId,
        public string $eventType
    ) {}

    public function handle(PushNotificationService $notifications): void
    {
        $application = ServiceApplication::query()->find($this->applicationId);
        if (! $application || $application->status !== 'pending') {
            return;
        }

        if (! $this->shouldSend($application->id, $this->eventType)) {
            return;
        }

        [$title, $message, $recipientIds] = $this->buildPayload($application);

        if ($recipientIds === []) {
            return;
        }

        $notifications->notifyUsers(
            $recipientIds,
            $title,
            $message,
            'service_application',
            $this->eventType,
            null,
            [
                'application_id' => $application->id,
                'category' => $application->category,
                'status' => $application->status,
            ]
        );
    }

    public function failed(Throwable $exception): void
    {
        logger()->error('SendServiceFollowUpJob failed', [
            'application_id' => $this->applicationId,
            'event_type' => $this->eventType,
            'error' => $exception->getMessage(),
        ]);
    }

    private function buildPayload(ServiceApplication $application): array
    {
        if ($this->eventType === 'service_application_pending_user') {
            return [
                'Pengajuan layanan masih diproses',
                "Pengajuan layanan {$application->category} Anda masih dalam antrean. Kami sedang memprosesnya.",
                [$application->user_id],
            ];
        }

        $adminIds = User::query()
            ->where('role', 'admin')
            ->pluck('id')
            ->map(fn($id) => (int) $id)
            ->all();

        return [
            'Pengajuan layanan menunggu review',
            "Pengajuan layanan {$application->category} belum diproses. Mohon dicek.",
            $adminIds,
        ];
    }

    private function shouldSend(int $applicationId, string $eventType): bool
    {
        return ! NotificationDispatchLog::query()
            ->where('module', 'service_application')
            ->where('event_type', $eventType)
            ->where('context->application_id', $applicationId)
            ->exists();
    }
}
