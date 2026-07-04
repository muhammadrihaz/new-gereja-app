<?php

namespace App\Jobs;

use App\Models\KKRegistration;
use App\Models\NotificationDispatchLog;
use App\Models\User;
use App\Services\PushNotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

class SendKkReminderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [60, 300, 900];

    public function __construct(public int $kkId) {}

    public function handle(PushNotificationService $notifications): void
    {
        $kk = KKRegistration::query()->find($this->kkId);
        if (! $kk) {
            return;
        }

        if (! $this->shouldSend($kk->id)) {
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

        $notifications->notifyUsers(
            $adminIds,
            'Data KK perlu ditindaklanjuti',
            "Data KK {$kk->nomor_kk} belum memiliki anggota terdaftar. Mohon dicek.",
            'kk_registration',
            'kk_followup_required',
            null,
            [
                'kk_id' => $kk->id,
                'nomor_kk' => $kk->nomor_kk,
            ]
        );
    }

    public function failed(Throwable $exception): void
    {
        logger()->error('SendKkReminderJob failed', [
            'kk_id' => $this->kkId,
            'error' => $exception->getMessage(),
        ]);
    }

    private function shouldSend(int $kkId): bool
    {
        return ! NotificationDispatchLog::query()
            ->where('module', 'kk_registration')
            ->where('event_type', 'kk_followup_required')
            ->where('context->kk_id', $kkId)
            ->exists();
    }
}
