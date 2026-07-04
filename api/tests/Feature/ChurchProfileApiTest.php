<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ChurchProfileApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_get_church_profile(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/church/profile');

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure([
                'status',
                'message',
                'data' => ['id', 'name', 'logo'],
                'trace_id',
            ]);
    }

    public function test_admin_can_upsert_church_profile_with_logo_json(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        $payload = [
            'name' => 'GPI Yehuda',
            'address' => 'Jl. Harapan 123',
            'phone' => '08123456789',
            'email' => 'admin@gpi-yehuda.local',
            'logo' => [
                'disk' => 'public',
                'path' => 'church/logo/main.png',
                'original_name' => 'logo.png',
                'mime' => 'image/png',
                'size' => 20480,
                'variants' => [
                    'thumb' => 'church/logo/thumb.png',
                ],
            ],
            'metadata' => [
                'timezone' => 'Asia/Makassar',
            ],
        ];

        $response = $this->putJson('/api/v1/church/profile', $payload);

        $response->assertOk()
            ->assertJsonPath('data.name', 'GPI Yehuda')
            ->assertJsonPath('data.logo.path', 'church/logo/main.png');

        $this->assertDatabaseHas('church_profiles', [
            'name' => 'GPI Yehuda',
        ]);
    }

    public function test_jemaat_cannot_upsert_church_profile(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        $response = $this->putJson('/api/v1/church/profile', [
            'name' => 'Not Allowed',
        ]);

        $response->assertForbidden();
    }
}
