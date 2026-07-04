<?php

namespace App\Console\Commands;

use App\Models\Event;
use App\Jobs\SendEventReminderJob;
use Carbon\Carbon;
use Illuminate\Console\Command;

class SendEventLastCallCommand extends Command
{
    protected $signature = 'notifications:events-last-call {--dry-run : Only output totals without sending}';

    protected $description = 'Send event reminders 60 minutes before start time.';

    public function handle(): int
    {
        $now = now();
        $windowStart = $now->copy()->addMinutes(50);
        $windowEnd = $now->copy()->addMinutes(70);

        $events = $this->loadEventsInWindow($windowStart, $windowEnd);
        if ($events->isEmpty()) {
            $this->info('No events in 1h reminder window.');
            return Command::SUCCESS;
        }

        $sentCount = 0;

        foreach ($events as $event) {
            if (! $this->option('dry-run')) {
                dispatch(new SendEventReminderJob($event->id, 'event_reminder_1h'));
            }

            $sentCount++;
        }

        $this->info("Event 1h reminders processed: {$sentCount} events.");

        return Command::SUCCESS;
    }

    private function loadEventsInWindow(Carbon $start, Carbon $end)
    {
        return Event::query()
            ->where(function ($query) use ($start, $end): void {
                $query->whereBetween('start_at', [$start, $end])
                    ->orWhere(function ($inner) use ($start, $end): void {
                        $inner->whereNull('start_at')->whereBetween('date', [$start, $end]);
                    });
            })
            ->get();
    }
}
