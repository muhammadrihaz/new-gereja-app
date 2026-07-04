<?php

namespace Tests\Feature\Devices;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DeviceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_device_success(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/devices/register', [
            'fcm_token' => str_repeat('x', 24),
            'device_name' => 'iPhone',
            'device_type' => 'ios',
        ]);

        $response->assertCreated()->assertJsonPath('status', 'success');
    }

    public function test_register_device_validation_error_when_token_missing(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/devices/register', [
            'device_type' => 'ios',
        ]);

        $response->assertUnprocessable()->assertJsonPath('error_code', 'VALIDATION_ERROR');
    }

    public function test_revoke_all_devices_success(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/devices/register', [
            'fcm_token' => str_repeat('m', 24),
            'device_name' => 'Android',
            'device_type' => 'android',
        ]);

        $response = $this->deleteJson('/api/v1/devices/revoke-all');
        $response->assertOk()->assertJsonPath('data.revoked_count', 1);
    }
}
