<?php

namespace App\Console\Commands;

use App\Models\Event;
use Illuminate\Console\Command;

class ArchiveExpiredEventsCommand extends Command
{
    protected $signature = 'events:archive-expired {--dry-run : Only report events that would be archived}';

    protected $description = 'Automatically archive events whose end time has passed. Members will no longer see archived events; church staff can still access them via the archive filter.';

    public function handle(): int
    {
        $now = now();
        $dryRun = (bool) $this->option('dry-run');

        // An event is considered expired when its end_at (or start_at as fallback) is in the past.
        $query = Event::query()
            ->where('is_archived', false)
            ->where(function ($q) use ($now): void {
                $q->where('end_at', '<', $now)
                  ->orWhere(function ($q2) use ($now): void {
                      $q2->whereNull('end_at')
                         ->where('start_at', '<', $now->copy()->subHours(6));
                  });
            });

        $count = $query->count();

        if ($count === 0) {
            $this->info('No expired events found. Nothing to archive.');
            return self::SUCCESS;
        }

        if ($dryRun) {
            $this->line("[DRY-RUN] Would archive {$count} event(s).");
            $query->get(['id', 'title', 'start_at', 'end_at'])->each(function ($event): void {
                $this->line(sprintf(
                    '  #%d "%s" start=%s end=%s',
                    $event->id,
                    $event->title,
                    optional($event->start_at)->toIso8601String() ?? '-',
                    optional($event->end_at)->toIso8601String() ?? '-'
                ));
            });
            return self::SUCCESS;
        }

        // Chunked update to avoid memory issues for large tables.
        $updated = 0;
        $query->chunkById(200, function ($events) use (&$updated, $now): void {
            foreach ($events as $event) {
                $event->update([
                    'is_archived' => true,
                    'archived_at' => $now,
                ]);
                $updated++;
            }
        });

        $this->info("Archived {$updated} event(s).");
        return self::SUCCESS;
    }
}
