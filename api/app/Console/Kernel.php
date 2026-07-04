<?php

namespace App\Console;

use App\Console\Commands\ArchiveExpiredEventsCommand;
use App\Console\Commands\SendEventLastCallCommand;
use App\Console\Commands\SendEventReminderCommand;
use App\Console\Commands\SendKkReminderCommand;
use App\Console\Commands\SendServiceFollowUpCommand;
use App\Console\Commands\SendAdminDigestCommand;
// use App\Console\Commands\SendTestEmailCommand;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    protected function schedule(Schedule $schedule): void
    {
        // Auto-archive expired events every 15 minutes so members no longer see them.
        $schedule->command(ArchiveExpiredEventsCommand::class)
            ->everyFifteenMinutes()
            ->withoutOverlapping()
            ->onOneServer();

        $schedule->command(SendEventReminderCommand::class)
            ->everyTenMinutes()
            ->withoutOverlapping()
            ->onOneServer();

        $schedule->command(SendEventLastCallCommand::class)
            ->everyTenMinutes()
            ->withoutOverlapping()
            ->onOneServer();

        $schedule->command(SendServiceFollowUpCommand::class)
            ->dailyAt('08:00')
            ->withoutOverlapping()
            ->onOneServer();

        $schedule->command(SendKkReminderCommand::class)
            ->dailyAt('09:00')
            ->withoutOverlapping()
            ->onOneServer();

        $schedule->command(SendAdminDigestCommand::class)
            ->weeklyOn(1, '08:30')
            ->withoutOverlapping()
            ->onOneServer();
    }

    protected function commands(): void
    {
        $this->load(__DIR__ . '/Commands');
    }
}
