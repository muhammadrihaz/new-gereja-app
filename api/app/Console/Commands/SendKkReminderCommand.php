<?php

namespace App\Console\Commands;

use App\Jobs\SendKkReminderJob;
use App\Models\KKRegistration;
use Carbon\Carbon;
use Illuminate\Console\Command;

class SendKkReminderCommand extends Command
{
    protected $signature = 'notifications:kk-followup {--dry-run : Only output totals without sending}';

    protected $description = 'Send follow-up reminders for KK registrations without members.';

    public function handle(): int
    {
        $cutoff = now()->subDays(7);

        $targets = KKRegistration::query()
            ->where('created_at', '<=', $cutoff)
            ->whereDoesntHave('members')
            ->get();

        if ($targets->isEmpty()) {
            $this->info('No KK registrations require follow-up.');
            return Command::SUCCESS;
        }

        if (! $this->option('dry-run')) {
            foreach ($targets as $kk) {
                dispatch(new SendKkReminderJob($kk->id));
            }
        }

        $this->info("KK follow-up queued: {$targets->count()} items.");

        return Command::SUCCESS;
    }
}
