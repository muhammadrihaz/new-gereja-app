<?php

namespace Tests\Feature\Notifications;

use App\Models\ServiceApplication;
use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BroadcastApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_broadcast_notification(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $jemaat = User::factory()->create(['role' => 'jemaat']);

        UserDevice::query()->create([
            'user_id' => $jemaat->id,
            'fcm_token' => str_repeat('z', 24),
            'device_name' => 'Pixel',
            'device_type' => 'android',
            'last_active' => now(),
        ]);

        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/notifications/broadcast', [
            'title' => 'Pengingat',
            'message' => 'Besok ibadah',
            'target_type' => 'all',
        ]);

        $response->assertOk()->assertJsonPath('data.target_count', 1);
    }

    public function test_jemaat_cannot_broadcast_notification(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        $response = $this->postJson('/api/v1/notifications/broadcast', [
            'title' => 'Pengingat',
            'message' => 'Besok ibadah',
            'target_type' => 'all',
        ]);

        $response->assertForbidden();
    }

    public function test_admin_can_broadcast_to_service_applicants_across_module(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $jemaatA = User::factory()->create(['role' => 'jemaat']);
        $jemaatB = User::factory()->create(['role' => 'jemaat']);

        ServiceApplication::query()->create([
            'user_id' => $jemaatA->id,
            'nomor_kk_snapshot' => '5171011111111111',
            'category' => 'baptisan',
            'form_data' => ['nama_lengkap' => 'A', 'tanggal_lahir' => '2020-01-01'],
            'attachments' => [],
            'status' => 'approved',
        ]);

        ServiceApplication::query()->create([
            'user_id' => $jemaatB->id,
            'nomor_kk_snapshot' => '5171012222222222',
            'category' => 'pernikahan',
            'form_data' => ['nama_mempelai_pria' => 'B', 'nama_mempelai_wanita' => 'C', 'tanggal_rencana' => '2026-04-10'],
            'attachments' => [],
            'status' => 'pending',
        ]);

        UserDevice::query()->create([
            'user_id' => $jemaatA->id,
            'fcm_token' => str_repeat('a', 24),
            'device_name' => 'A-phone',
            'device_type' => 'android',
            'last_active' => now(),
        ]);

        UserDevice::query()->create([
            'user_id' => $jemaatB->id,
            'fcm_token' => str_repeat('b', 24),
            'device_name' => 'B-phone',
            'device_type' => 'ios',
            'last_active' => now(),
        ]);

        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/notifications/broadcast', [
            'title' => 'Status Layanan',
            'message' => 'Update status layanan baptisan',
            'target_type' => 'service_applicants',
            'target_filters' => [
                'service_category' => 'baptisan',
                'service_status' => 'approved',
            ],
        ]);

        $response->assertOk()->assertJsonPath('data.target_count', 1);
    }
}
