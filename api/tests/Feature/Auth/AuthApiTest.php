<?php

namespace Tests\Feature\Auth;

use App\Models\KKRegistration;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->withoutMiddleware(\Illuminate\Routing\Middleware\ThrottleRequests::class);
    }

    public function test_register_success_with_fcm_token(): void
    {
        KKRegistration::query()->create([
            'nomor_kk' => '5171012345678901',
            'nama_kepala_keluarga' => 'Nova Jemaat',
        ]);

        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Nova Jemaat',
            'username' => 'nova01',
            'email' => 'nova@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'nomor_kk' => '5171012345678901',
            'fcm_token' => str_repeat('a', 24),
        ]);

        $response->assertCreated()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.role', 'jemaat');
    }

    public function test_register_fails_when_nomor_kk_missing(): void
    {
        $response = $this->withHeader('X-Forwarded-For', '10.10.10.2')->postJson('/api/v1/auth/register', [
            'username' => 'novatanpakk',
            'email' => 'novatanpakk@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'fcm_token' => str_repeat('z', 24),
        ]);

        $response->assertUnprocessable()
            ->assertJsonPath('error_code', 'VALIDATION_ERROR');
    }

    public function test_login_success_and_return_token(): void
    {
        User::factory()->create([
            'email' => 'nova@example.com',
            'password' => 'password123',
            'username' => 'nova01',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'username' => 'nova01',
            'password' => 'password123',
            'fcm_token' => str_repeat('b', 24),
        ]);

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure(['data' => ['token']]);
    }

    public function test_login_success_with_email(): void
    {
        User::factory()->create([
            'email' => 'nova@example.com',
            'password' => 'password123',
            'username' => 'nova01',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'username' => 'nova@example.com',
            'password' => 'password123',
            'fcm_token' => str_repeat('b', 24),
        ]);

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure(['data' => ['token']]);
    }

    public function test_me_endpoint_requires_valid_token(): void
    {
        $this->getJson('/api/v1/auth/me')->assertUnauthorized();
    }

    public function test_logout_deletes_token(): void
    {
        $user = User::factory()->create([
            'username' => 'admin01',
        ]);

        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/auth/logout');

        $response->assertOk()->assertJsonPath('status', 'success');
    }

    public function test_authenticated_user_can_update_profile(): void
    {
        $user = User::factory()->create([
            'username' => 'jemaat01',
            'email' => 'jemaat01@example.com',
        ]);
        Sanctum::actingAs($user);

        $response = $this->patchJson('/api/v1/auth/me', [
            'username' => 'jemaat-update',
            'email' => 'jemaat-update@example.com',
            'name' => 'Jemaat Update',
            'alamat' => 'Kuta, Bali',
        ]);

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.username', 'jemaat-update');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'username' => 'jemaat-update',
            'email' => 'jemaat-update@example.com',
        ]);
    }

    public function test_authenticated_user_can_upload_profile_photo(): void
    {
        Storage::fake('public');

        $user = User::factory()->create([
            'username' => 'fotojemaat',
            'email' => 'fotojemaat@example.com',
        ]);

        Sanctum::actingAs($user);

        $response = $this->post('/api/v1/auth/me/photo', [
            'photo' => UploadedFile::fake()->create('avatar.jpg', 120, 'image/jpeg'),
        ]);

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('message', 'Foto profil berhasil diperbarui');

        $user->refresh();
        $this->assertNotNull($user->profile_photo_path);
        $this->assertTrue((bool) Storage::disk('public')->exists((string) $user->profile_photo_path));
    }
}
