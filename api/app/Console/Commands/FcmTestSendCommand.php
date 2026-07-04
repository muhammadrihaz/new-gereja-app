<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Models\UserDevice;
use App\Services\PushNotificationService;
use Illuminate\Console\Command;

/**
 * Sends a real FCM push notification to verify end-to-end delivery.
 *
 * Usage:
 *   # Send to all devices belonging to a user
 *   php artisan fcm:test-send --user=1
 *
 *   # Send to a single explicit FCM token (useful when the token is generated
 *   # from a test app / device that is not yet linked to a user record)
 *   php artisan fcm:test-send --token=<fcm-token>
 *
 *   # Custom title / body
 *   php artisan fcm:test-send --user=1 --title="Uji FCM" --message="Halo dari server"
 */
class FcmTestSendCommand extends Command
{
    protected $signature = 'fcm:test-send
        {--user= : Target user id (uses all of the user\'s registered devices)}
        {--token=* : One or more explicit FCM device tokens}
        {--title=Test FCM v1 : Notification title}
        {--message=Halo dari GPI Yehuda. Ini adalah tes FCM v1 dari server. : Notification body}';

    protected $description = 'Send a real push notification via FCM HTTP v1 to verify end-to-end delivery.';

    public function handle(PushNotificationService $push): int
    {
        $userId = $this->option('user');
        $explicitTokens = (array) $this->option('token');
        $title = (string) $this->option('title');
        $message = (string) $this->option('message');

        $devices = [];

        if ($userId !== null && $userId !== '') {
            $user = User::query()->find((int) $userId);
            if ($user === null) {
                $this->error("User #{$userId} not found.");
                return self::FAILURE;
            }
            $rows = UserDevice::query()->where('user_id', $user->id)->get(['user_id', 'fcm_token']);
            if ($rows->isEmpty()) {
                $this->warn("User #{$userId} has no registered devices.");
            }
            foreach ($rows as $r) {
                $devices[] = ['user_id' => (int) $r->user_id, 'fcm_token' => (string) $r->fcm_token];
            }
        }

        foreach ($explicitTokens as $t) {
            $t = trim((string) $t);
            if ($t === '') {
                continue;
            }
            $devices[] = ['user_id' => (int) ($userId ?? 0), 'fcm_token' => $t];
        }

        if ($devices === []) {
            $this->error('No devices to notify. Pass --user or --token.');
            return self::FAILURE;
        }

        $this->info('Sending to ' . count($devices) . ' device(s)...');
        $result = $push->notifyDevices(
            $devices,
            $title,
            $message,
            module: 'diagnostic',
            eventType: 'fcm_test_send',
            context: ['source' => 'artisan_command']
        );

        $this->line('----------------------------------------');
        $this->line('target_count : ' . $result['target_count']);
        $this->line('success      : ' . $result['success_count']);
        $this->line('queued       : ' . $result['queued_count']);
        $this->line('failed       : ' . $result['failed_count']);

        if ($result['success_count'] === 0) {
            $this->error('No deliveries succeeded. Run `php artisan fcm:diagnose` to check the FCM v1 config.');
            return self::FAILURE;
        }

        return self::SUCCESS;
    }
}
