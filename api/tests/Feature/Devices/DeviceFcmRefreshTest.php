<?php

namespace Tests\Feature\Devices;

use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DeviceFcmRefreshTest extends TestCase
{
    use RefreshDatabase;

    public function test_creates_new_device_when_none_exists(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/devices/fcm-refresh', [
            'new_fcm_token' => str_repeat('a', 40),
            'device_type' => 'android',
            'device_name' => 'Pixel 9',
        ]);

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.fcm_token', str_repeat('a', 40))
            ->assertJsonPath('data.device_type', 'android');

        $this->assertDatabaseHas('user_devices', [
            'user_id' => $user->id,
            'fcm_token' => str_repeat('a', 40),
            'device_name' => 'Pixel 9',
        ]);
    }

    public function test_migrates_existing_device_row_when_old_token_provided(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $old = UserDevice::query()->create([
            'user_id' => $user->id,
            'fcm_token' => str_repeat('o', 40),
            'device_type' => 'android',
            'device_name' => 'Pixel 9',
            'last_active' => now()->subDays(1),
        ]);

        $newToken = str_repeat('n', 40);
        $response = $this->postJson('/api/v1/devices/fcm-refresh', [
            'old_fcm_token' => str_repeat('o', 40),
            'new_fcm_token' => $newToken,
            'device_type' => 'android',
            'device_name' => 'Pixel 9',
        ]);

        $response->assertOk()->assertJsonPath('data.fcm_token', $newToken);

        // Same row id, just token migrated in place (no duplicate).
        $this->assertDatabaseCount('user_devices', 1);
        $this->assertDatabaseHas('user_devices', [
            'id' => $old->id,
            'fcm_token' => $newToken,
            'user_id' => $user->id,
        ]);
    }

    public function test_is_idempotent_when_called_repeatedly_with_same_new_token(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $token = str_repeat('x', 40);
        $payload = [
            'new_fcm_token' => $token,
            'device_type' => 'ios',
            'device_name' => 'iPhone 15',
        ];

        $r1 = $this->postJson('/api/v1/devices/fcm-refresh', $payload);
        $r2 = $this->postJson('/api/v1/devices/fcm-refresh', $payload);
        $r3 = $this->postJson('/api/v1/devices/fcm-refresh', $payload);

        $r1->assertOk();
        $r2->assertOk();
        $r3->assertOk();

        // Exactly one row.
        $this->assertDatabaseCount('user_devices', 1);
    }

    public function test_claims_token_owned_by_previous_user_after_reinstall(): void
    {
        $oldOwner = User::factory()->create();
        $token = str_repeat('r', 40);
        UserDevice::query()->create([
            'user_id' => $oldOwner->id,
            'fcm_token' => $token,
            'device_type' => 'android',
            'device_name' => 'Reused Pixel',
            'last_active' => now()->subDays(30),
        ]);

        $newOwner = User::factory()->create();
        Sanctum::actingAs($newOwner);

        $response = $this->postJson('/api/v1/devices/fcm-refresh', [
            'new_fcm_token' => $token,
            'device_type' => 'android',
            'device_name' => 'Pixel 9',
        ]);

        $response->assertOk();
        $this->assertDatabaseCount('user_devices', 1);
        $this->assertDatabaseHas('user_devices', [
            'fcm_token' => $token,
            'user_id' => $newOwner->id,
        ]);
    }

    public function test_deletes_old_token_after_migration(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $oldToken = str_repeat('o', 40);
        $newToken = str_repeat('n', 40);

        // Explicitly seed BOTH old and new to simulate a race where the new
        // token was already registered by another codepath, then we refresh
        // with the old_fcm_token pointer.
        UserDevice::query()->create([
            'user_id' => $user->id,
            'fcm_token' => $oldToken,
            'device_type' => 'android',
            'device_name' => 'Pixel 9',
            'last_active' => now()->subDays(1),
        ]);
        UserDevice::query()->create([
            'user_id' => $user->id,
            'fcm_token' => $newToken,
            'device_type' => 'android',
            'device_name' => 'Pixel 9',
            'last_active' => now()->subHours(1),
        ]);

        $response = $this->postJson('/api/v1/devices/fcm-refresh', [
            'old_fcm_token' => $oldToken,
            'new_fcm_token' => $newToken,
            'device_type' => 'android',
            'device_name' => 'Pixel 9',
        ]);

        $response->assertOk();
        $this->assertDatabaseCount('user_devices', 1);
        $this->assertDatabaseMissing('user_devices', ['fcm_token' => $oldToken]);
        $this->assertDatabaseHas('user_devices', [
            'fcm_token' => $newToken,
            'user_id' => $user->id,
        ]);
    }

    public function test_requires_authentication(): void
    {
        $response = $this->postJson('/api/v1/devices/fcm-refresh', [
            'new_fcm_token' => str_repeat('a', 40),
            'device_type' => 'android',
        ]);
        $response->assertUnauthorized();
    }

    public function test_validates_required_fields(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);
        $response = $this->postJson('/api/v1/devices/fcm-refresh', [
            'new_fcm_token' => 'too-short',
            'device_type' => 'martian',
        ]);
        $response->assertStatus(422)->assertJsonValidationErrors(['new_fcm_token', 'device_type']);
    }
}
