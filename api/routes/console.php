<?php

use App\Console\Commands\ArchiveExpiredEventsCommand;
use App\Console\Commands\SendAdminDigestCommand;
use App\Console\Commands\SendEventLastCallCommand;
use App\Console\Commands\SendEventReminderCommand;
use App\Console\Commands\SendKkReminderCommand;
use App\Console\Commands\SendServiceFollowUpCommand;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

/*
|--------------------------------------------------------------------------
| Scheduled tasks
|--------------------------------------------------------------------------
|
| Laravel 11+ no longer auto-loads App\Console\Kernel::schedule(). All
| scheduled tasks must be declared here (or via bootstrap/app.php withSchedule).
|
*/

// Auto-archive expired events so members only see active/upcoming.
Schedule::command(ArchiveExpiredEventsCommand::class)
    ->everyFifteenMinutes()
    ->withoutOverlapping()
    ->onOneServer();

// Push reminders for events (H-2 and H-1).
Schedule::command(SendEventReminderCommand::class)
    ->everyTenMinutes()
    ->withoutOverlapping()
    ->onOneServer();

Schedule::command(SendEventLastCallCommand::class)
    ->everyTenMinutes()
    ->withoutOverlapping()
    ->onOneServer();

// Follow-up on stale service applications.
Schedule::command(SendServiceFollowUpCommand::class)
    ->dailyAt('08:00')
    ->withoutOverlapping()
    ->onOneServer();

// Kartu Keluarga registration reminders.
Schedule::command(SendKkReminderCommand::class)
    ->dailyAt('09:00')
    ->withoutOverlapping()
    ->onOneServer();

// Weekly admin digest.
Schedule::command(SendAdminDigestCommand::class)
    ->weeklyOn(1, '08:30')
    ->withoutOverlapping()
    ->onOneServer();
