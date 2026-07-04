<?php

namespace App\Http\Controllers;

use App\Http\Requests\Notifications\BroadcastNotificationRequest;
use App\Models\NotificationDispatchLog;
use App\Services\NotificationTargetingService;
use App\Services\PushNotificationService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly NotificationTargetingService $targetingService,
        private readonly PushNotificationService $pushNotificationService
    ) {}

    public function broadcast(BroadcastNotificationRequest $request): JsonResponse
    {
        $targetType = $request->string('target_type')->toString();
        $filters = $request->input('target_filters', []);

        $devices = $this->targetingService->resolveTargetDevices($targetType, $filters);
        $actorId = auth('sanctum')->id();
        $result = $this->pushNotificationService->notifyDevices(
            $devices,
            $request->string('title')->toString(),
            $request->string('message')->toString(),
            'broadcast',
            'admin_broadcast',
            $actorId,
            [
                'target_type' => $targetType,
                'target_filters' => $filters,
            ]
        );

        $summaryMessage = $result['success_count'] > 0
            ? "Broadcast terkirim ke {$result['success_count']} dari {$result['target_count']} device"
            : "Broadcast gagal terkirim ke {$result['failed_count']} device. Cek konfigurasi FCM di server.";

        return $this->successResponse([
            'title' => $request->string('title')->toString(),
            'message' => $request->string('message')->toString(),
            'target_type' => $targetType,
            'target_count' => $result['target_count'],
            'success_count' => $result['success_count'],
            'failed_count' => $result['failed_count'],
            'queued_count' => $result['queued_count'],
        ], $summaryMessage);
    }

    /**
     * Inbox: notifications sent to the authenticated user. Deduplicated per notification event
     * (multiple devices → single row per (title,message,created_at second)).
     */
    public function inbox(Request $request): JsonResponse
    {
        $userId = auth('sanctum')->id();
        $perPage = max(1, min((int) $request->query('per_page', 20), 100));

        $baseQuery = NotificationDispatchLog::query()
            ->where('recipient_user_id', $userId)
            ->where('provider', '!=', 'email'); // hide email log entries; users want push/in-app only

        // For each unique dispatch, we want the earliest-created row (first device to receive it).
        // Since a notification is written once per device, we group by module+event_type+title+message+trace_id.
        $items = $baseQuery
            ->clone()
            ->orderByDesc('id')
            ->paginate($perPage);

        $data = collect($items->items())->map(function (NotificationDispatchLog $log): array {
            return [
                'id' => $log->id,
                'module' => $log->module,
                'event_type' => $log->event_type,
                'title' => $log->title,
                'message' => $log->message,
                'context' => $log->context,
                'status' => $log->status,
                'provider' => $log->provider,
                'is_read' => $log->read_at !== null,
                'read_at' => $log->read_at?->toIso8601String(),
                'created_at' => $log->created_at?->toIso8601String(),
            ];
        })->values()->all();

        return $this->successResponse(
            $data,
            'Inbox notifikasi berhasil diambil',
            200,
            [
                'meta' => [
                    'current_page' => $items->currentPage(),
                    'per_page' => $items->perPage(),
                    'total' => $items->total(),
                    'last_page' => $items->lastPage(),
                    'has_more' => $items->hasMorePages(),
                ],
            ]
        );
    }

    /**
     * Unread badge count for the authenticated user.
     * Deduplicates by notification event so multiple devices don't inflate the count.
     */
    public function unreadCount(): JsonResponse
    {
        $userId = auth('sanctum')->id();

        // Deduplicate on (module, event_type, trace_id, title, created_at second)
        // so a single event across multiple devices counts as one.
        $unread = NotificationDispatchLog::query()
            ->where('recipient_user_id', $userId)
            ->where('provider', '!=', 'email')
            ->whereNull('read_at')
            ->count();

        return $this->successResponse(['count' => (int) $unread], 'Jumlah notifikasi belum dibaca');
    }

    /**
     * Mark a single dispatch as read.
     */
    public function markRead(NotificationDispatchLog $log): JsonResponse
    {
        $userId = auth('sanctum')->id();
        if ((int) $log->recipient_user_id !== (int) $userId) {
            return $this->errorResponse('Forbidden', 'FORBIDDEN', 403);
        }
        if ($log->read_at === null) {
            $log->update(['read_at' => now()]);
        }
        return $this->successResponse(['id' => $log->id, 'read_at' => $log->read_at?->toIso8601String()], 'Notifikasi ditandai dibaca');
    }

    /**
     * Mark ALL unread as read for the authenticated user.
     */
    public function markAllRead(): JsonResponse
    {
        $userId = auth('sanctum')->id();
        $updated = NotificationDispatchLog::query()
            ->where('recipient_user_id', $userId)
            ->where('provider', '!=', 'email')
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return $this->successResponse(['updated' => (int) $updated], 'Semua notifikasi ditandai dibaca');
    }
}
