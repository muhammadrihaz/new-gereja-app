<?php

namespace Tests\Feature\Notifications;

use App\Models\NotificationDispatchLog;
use App\Models\User;
use App\Models\UserDevice;
use App\Services\FcmAccessTokenProvider;
use App\Services\PushNotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class FcmV1PushTest extends TestCase
{
    use RefreshDatabase;

    private function bindTokenProvider(?array $auth): void
    {
        $mock = $this->createMock(FcmAccessTokenProvider::class);
        $mock->method('fetch')->willReturn($auth);
        $this->app->instance(FcmAccessTokenProvider::class, $mock);
    }

    protected function setUp(): void
    {
        parent::setUp();
        config()->set('services.fcm.enabled', true);
        config()->set('services.fcm.server_key', ''); // force v1
    }

    public function test_sends_via_fcm_v1_when_credentials_available(): void
    {
        $this->bindTokenProvider([
            'token' => 'ya29.test-access-token',
            'project_id' => 'new-gereja-gpi',
        ]);

        Http::fake([
            'https://fcm.googleapis.com/v1/projects/new-gereja-gpi/messages:send' => Http::response([
                'name' => 'projects/new-gereja-gpi/messages/0:abcd',
            ], 200),
        ]);

        $user = User::factory()->create();
        $device = ['user_id' => $user->id, 'fcm_token' => 'device-token-abc'];

        /** @var PushNotificationService $push */
        $push = $this->app->make(PushNotificationService::class);
        $result = $push->notifyDevices([$device], 'Judul', 'Pesan', 'test', 'unit_test');

        $this->assertSame(1, $result['success_count']);
        $this->assertSame(0, $result['failed_count']);
        $this->assertSame(0, $result['queued_count']);

        Http::assertSent(function ($request): bool {
            if (! str_contains($request->url(), '/v1/projects/new-gereja-gpi/messages:send')) {
                return false;
            }
            $body = json_decode($request->body() ?: '{}', true);
            $token = data_get($body, 'message.token');
            $title = data_get($body, 'message.notification.title');
            $body_ = data_get($body, 'message.notification.body');
            $channel = data_get($body, 'message.android.notification.channel_id');
            return $token === 'device-token-abc'
                && $title === 'Judul'
                && $body_ === 'Pesan'
                && $channel === 'high_importance_channel'
                && $request->hasHeader('Authorization', 'Bearer ya29.test-access-token');
        });

        $log = NotificationDispatchLog::query()->first();
        $this->assertNotNull($log);
        $this->assertSame('sent', $log->status);
        $this->assertSame('fcm_v1', $log->provider);
    }

    public function test_invalidates_dead_tokens_on_unregistered_error(): void
    {
        $this->bindTokenProvider([
            'token' => 'ya29.test-access-token',
            'project_id' => 'new-gereja-gpi',
        ]);

        Http::fake([
            'https://fcm.googleapis.com/v1/projects/*/messages:send' => Http::response([
                'error' => [
                    'code' => 404,
                    'message' => 'Requested entity was not found.',
                    'status' => 'NOT_FOUND',
                    'details' => [
                        [
                            '@type' => 'type.googleapis.com/google.firebase.fcm.v1.FcmError',
                            'errorCode' => 'UNREGISTERED',
                        ],
                    ],
                ],
            ], 404),
        ]);

        $user = User::factory()->create();
        $token = 'dead-token-xyz';
        UserDevice::query()->create([
            'user_id' => $user->id,
            'fcm_token' => $token,
            'device_type' => 'android',
            'device_name' => 'Old device',
            'last_active' => now(),
        ]);

        /** @var PushNotificationService $push */
        $push = $this->app->make(PushNotificationService::class);
        $result = $push->notifyDevices(
            [['user_id' => $user->id, 'fcm_token' => $token]],
            'Judul',
            'Pesan',
            'test',
            'unit_test'
        );

        $this->assertSame(0, $result['success_count']);
        $this->assertSame(1, $result['failed_count']);
        $this->assertDatabaseMissing('user_devices', ['fcm_token' => $token]);
    }

    public function test_deduplicates_repeated_tokens(): void
    {
        $this->bindTokenProvider([
            'token' => 'ya29.dedupe',
            'project_id' => 'new-gereja-gpi',
        ]);

        Http::fake([
            'https://fcm.googleapis.com/v1/projects/*/messages:send' => Http::response(['name' => 'ok'], 200),
        ]);

        $user = User::factory()->create();
        $token = 'same-token-123';

        $devices = [
            ['user_id' => $user->id, 'fcm_token' => $token],
            ['user_id' => $user->id, 'fcm_token' => $token],
            ['user_id' => $user->id, 'fcm_token' => $token],
        ];

        /** @var PushNotificationService $push */
        $push = $this->app->make(PushNotificationService::class);
        $result = $push->notifyDevices($devices, 'A', 'B', 'test', 'dedupe');

        $this->assertSame(1, $result['target_count']);
        $this->assertSame(1, $result['success_count']);
        Http::assertSentCount(1);
    }

    public function test_queues_when_fcm_not_configured(): void
    {
        $this->bindTokenProvider(null); // v1 unavailable
        config()->set('services.fcm.server_key', ''); // legacy unavailable
        config()->set('services.fcm.enabled', true);

        $user = User::factory()->create();
        $device = ['user_id' => $user->id, 'fcm_token' => 'anything-token'];

        /** @var PushNotificationService $push */
        $push = $this->app->make(PushNotificationService::class);
        $result = $push->notifyDevices([$device], 'A', 'B', 'test', 'noop');

        $this->assertSame(0, $result['success_count']);
        $this->assertSame(1, $result['queued_count']);
        $log = NotificationDispatchLog::query()->first();
        $this->assertSame('queued', $log->status);
        $this->assertSame('fcm_not_configured', data_get($log->provider_response, 'reason'));
    }

    public function test_diagnose_command_reports_missing_credentials(): void
    {
        config()->set('services.fcm.credentials_json', '');
        config()->set('services.fcm.credentials_base64', '');
        config()->set('services.fcm.enabled', false);

        $this->artisan('fcm:diagnose')->assertExitCode(1);
    }

    public function test_diagnose_command_reports_ok_when_provider_returns_token(): void
    {
        $this->bindTokenProvider([
            'token' => 'ya29.diag',
            'project_id' => 'new-gereja-gpi',
        ]);
        // Fake credentials source so the diagnose command reports it correctly.
        config()->set('services.fcm.credentials_base64', base64_encode('{"placeholder":true}'));
        config()->set('services.fcm.enabled', true);

        Http::fake([
            'https://fcm.googleapis.com/v1/*' => Http::response('ok', 200),
        ]);

        $this->artisan('fcm:diagnose')->assertExitCode(0);
    }
}
