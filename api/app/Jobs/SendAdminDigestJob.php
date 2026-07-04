<?php

namespace App\Jobs;

use App\Models\NotificationDispatchLog;
use App\Models\User;
use App\Services\PushNotificationService;
use Carbon\Carbon;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

class SendAdminDigestJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [60, 300, 900];

    public function __construct(
        public int $pendingServices,
        public int $staleKkCount,
        public string $weekStart
    ) {}

    public function handle(PushNotificationService $notifications): void
    {
        if (! $this->shouldSend($this->weekStart)) {
            return;
        }

        $adminIds = User::query()
            ->where('role', 'admin')
            ->pluck('id')
            ->map(fn($id) => (int) $id)
            ->all();

        if ($adminIds === []) {
            return;
        }

        $message = sprintf(
            'Ringkasan minggu ini: %d pengajuan layanan pending, %d KK perlu ditindaklanjuti.',
            $this->pendingServices,
            $this->staleKkCount
        );

        $notifications->notifyUsers(
            $adminIds,
            'Ringkasan Admin Mingguan',
            $message,
            'admin_digest',
            'admin_digest_weekly',
            null,
            [
                'week_start' => $this->weekStart,
                'pending_services' => $this->pendingServices,
                'kk_followups' => $this->staleKkCount,
            ]
        );
    }

    public function failed(Throwable $exception): void
    {
        logger()->error('SendAdminDigestJob failed', [
            'week_start' => $this->weekStart,
            'error' => $exception->getMessage(),
        ]);
    }

    private function shouldSend(string $weekStart): bool
    {
        return ! NotificationDispatchLog::query()
            ->where('module', 'admin_digest')
            ->where('event_type', 'admin_digest_weekly')
            ->where('context->week_start', $weekStart)
            ->exists();
    }
}
