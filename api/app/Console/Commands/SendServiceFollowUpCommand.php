<?php

namespace App\Console\Commands;

use App\Jobs\SendServiceFollowUpJob;
use App\Models\ServiceApplication;
use Carbon\Carbon;
use Illuminate\Console\Command;

class SendServiceFollowUpCommand extends Command
{
    protected $signature = 'notifications:services-followup {--dry-run : Only output totals without sending}';

    protected $description = 'Send follow-up reminders for pending service applications.';

    public function handle(): int
    {
        $now = now();
        $adminCutoff = $now->copy()->subDays(3);
        $userCutoff = $now->copy()->subDays(7);

        $adminTargets = ServiceApplication::query()
            ->where('status', 'pending')
            ->where('created_at', '<=', $adminCutoff)
            ->get();

        $userTargets = ServiceApplication::query()
            ->where('status', 'pending')
            ->where('created_at', '<=', $userCutoff)
            ->get();

        if ($adminTargets->isEmpty() && $userTargets->isEmpty()) {
            $this->info('No pending service applications require follow-up.');
            return Command::SUCCESS;
        }

        if (! $this->option('dry-run')) {
            foreach ($adminTargets as $application) {
                dispatch(new SendServiceFollowUpJob($application->id, 'service_application_pending_admin'));
            }

            foreach ($userTargets as $application) {
                dispatch(new SendServiceFollowUpJob($application->id, 'service_application_pending_user'));
            }
        }

        $this->info(sprintf(
            'Service follow-up queued. Admin: %d, User: %d.',
            $adminTargets->count(),
            $userTargets->count()
        ));

        return Command::SUCCESS;
    }
}
