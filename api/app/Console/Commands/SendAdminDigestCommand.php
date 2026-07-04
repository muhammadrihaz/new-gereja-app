<?php

namespace App\Console\Commands;

use App\Jobs\SendAdminDigestJob;
use App\Models\KKRegistration;
use App\Models\ServiceApplication;
use Carbon\Carbon;
use Illuminate\Console\Command;

class SendAdminDigestCommand extends Command
{
    protected $signature = 'notifications:admin-digest {--dry-run : Only output totals without sending}';

    protected $description = 'Send weekly admin digest with pending counts.';

    public function handle(): int
    {
        $pendingServices = ServiceApplication::query()->where('status', 'pending')->count();

        $staleKkCount = KKRegistration::query()
            ->where('created_at', '<=', now()->subDays(7))
            ->whereDoesntHave('members')
            ->count();

        $weekStart = now()->startOfWeek()->format('Y-m-d');

        if (! $this->option('dry-run')) {
            dispatch(new SendAdminDigestJob($pendingServices, $staleKkCount, $weekStart));
        }

        $this->info(sprintf(
            'Admin digest queued. Pending services: %d, KK follow-ups: %d.',
            $pendingServices,
            $staleKkCount
        ));

        return Command::SUCCESS;
    }
}
