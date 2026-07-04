<?php

namespace Tests\Unit;

use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceTokenUpsertTest extends TestCase
{
    use RefreshDatabase;

    public function test_same_fcm_token_updates_existing_record(): void
    {
        $user = User::factory()->create();

        UserDevice::query()->updateOrCreate(
            ['fcm_token' => str_repeat('k', 24)],
            [
                'user_id' => $user->id,
                'device_name' => 'old-name',
                'device_type' => 'android',
                'last_active' => now()->subDay(),
            ]
        );

        UserDevice::query()->updateOrCreate(
            ['fcm_token' => str_repeat('k', 24)],
            [
                'user_id' => $user->id,
                'device_name' => 'new-name',
                'device_type' => 'ios',
                'last_active' => now(),
            ]
        );

        $this->assertDatabaseCount('user_devices', 1);
        $this->assertDatabaseHas('user_devices', [
            'fcm_token' => str_repeat('k', 24),
            'device_name' => 'new-name',
            'device_type' => 'ios',
        ]);
    }
}
