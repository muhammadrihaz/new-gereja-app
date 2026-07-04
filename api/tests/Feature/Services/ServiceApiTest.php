<?php

namespace Tests\Feature\Services;

use App\Models\ServiceApplication;
use App\Models\UserDevice;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ServiceApiTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @return array<string, array{category: string, form_data: array<string, mixed>}>
     */
    private function categoryPayloads(): array
    {
        return [
            'baptisan' => [
                'category' => 'baptisan',
                'form_data' => [
                    'nama_lengkap' => 'Anak A',
                    'tanggal_lahir' => '2026-01-01',
                ],
            ],
            'pernikahan' => [
                'category' => 'pernikahan',
                'form_data' => [
                    'nama_mempelai_pria' => 'Pria A',
                    'nama_mempelai_wanita' => 'Wanita B',
                    'tanggal_rencana' => '2026-06-01',
                ],
            ],
            'penyerahan_anak' => [
                'category' => 'penyerahan_anak',
                'form_data' => [
                    'nama_anak' => 'Anak C',
                    'tanggal_lahir' => '2025-05-10',
                    'nama_orang_tua' => 'Keluarga C',
                ],
            ],
            'permohonan_doa' => [
                'category' => 'permohonan_doa',
                'form_data' => [
                    'pokok_doa' => 'Doa kesembuhan',
                ],
            ],
        ];
    }

    public function test_categories_endpoint_returns_list(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/services/categories');

        $response->assertOk()->assertJsonPath('status', 'success');
        $response->assertJsonFragment(['code' => 'baptisan']);
    }

    public function test_apply_service_success(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        UserDevice::query()->create([
            'user_id' => $admin->id,
            'fcm_token' => str_repeat('n', 24),
            'device_name' => 'Admin Device',
            'device_type' => 'android',
            'last_active' => now(),
        ]);

        $user = User::factory()->create(['nomor_kk' => '5171012345678901']);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/services/apply', [
            'category' => 'baptisan',
            'form_data' => [
                'nama_lengkap' => 'Anak A',
                'tanggal_lahir' => '2026-01-01',
            ],
            'attachments' => ['https://files/kk.pdf'],
        ]);

        $response->assertCreated()->assertJsonPath('status', 'success');
        $response->assertJsonPath('data.nomor_kk_snapshot', '5171012345678901');

        $this->assertDatabaseHas('notification_dispatch_logs', [
            'recipient_user_id' => $admin->id,
            'module' => 'service_application',
            'event_type' => 'service_application_submitted',
        ]);

        $rawEncryptedAttachments = DB::table('service_applications')
            ->where('id', $response->json('data.id'))
            ->value('attachments');

        $this->assertIsString($rawEncryptedAttachments);
        $this->assertStringNotContainsString('https://files/kk.pdf', $rawEncryptedAttachments);
    }

    public function test_jemaat_can_apply_for_all_active_categories(): void
    {
        $user = User::factory()->create(['nomor_kk' => '5171017777777777']);
        Sanctum::actingAs($user);

        foreach ($this->categoryPayloads() as $payload) {
            $response = $this->postJson('/api/v1/services/apply', [
                'category' => $payload['category'],
                'form_data' => $payload['form_data'],
                'attachments' => [],
            ]);

            $response->assertCreated()->assertJsonPath('data.category', $payload['category']);
        }
    }

    public function test_apply_service_validation_fails_when_required_dynamic_field_missing(): void
    {
        $user = User::factory()->create(['nomor_kk' => '5171012345678901']);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/services/apply', [
            'category' => 'baptisan',
            'form_data' => [
                'nama_lengkap' => 'Anak A',
            ],
        ]);

        $response->assertUnprocessable()->assertJsonPath('error_code', 'VALIDATION_ERROR');
    }

    public function test_apply_service_fails_when_jemaat_nomor_kk_missing(): void
    {
        $user = User::factory()->create(['nomor_kk' => null]);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/services/apply', [
            'category' => 'baptisan',
            'form_data' => [
                'nama_lengkap' => 'Anak A',
                'tanggal_lahir' => '2026-01-01',
            ],
        ]);

        $response->assertUnprocessable()->assertJsonPath('error_code', 'VALIDATION_ERROR');
    }

    public function test_admin_can_create_or_update_service_template_for_existing_category(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/services/forms', [
            'category' => 'baptisan',
            'name' => 'Form Baptisan Khusus',
            'is_active' => true,
            'fields' => [
                ['key' => 'nama_lengkap', 'type' => 'string', 'required' => true],
                ['key' => 'jadwal_preferensi', 'type' => 'string', 'required' => true],
            ],
        ]);

        $response->assertOk()->assertJsonPath('data.category', 'baptisan');

        $this->assertDatabaseHas('service_form_templates', [
            'category' => 'baptisan',
            'name' => 'Form Baptisan Khusus',
        ]);
    }

    public function test_admin_cannot_create_template_for_unknown_category(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/services/forms', [
            'category' => 'konseling',
            'name' => 'Form Konseling',
            'is_active' => true,
            'fields' => [
                ['key' => 'nama_lengkap', 'type' => 'string', 'required' => true],
            ],
        ]);

        $response->assertUnprocessable()->assertJsonPath('error_code', 'VALIDATION_ERROR');
    }

    public function test_jemaat_cannot_manage_service_template(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        $response = $this->postJson('/api/v1/services/forms', [
            'category' => 'konseling',
            'name' => 'Form Konseling',
            'fields' => [
                ['key' => 'nama_lengkap', 'type' => 'string', 'required' => true],
            ],
        ]);

        $response->assertForbidden();
    }

    public function test_admin_can_update_application_status(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        UserDevice::query()->create([
            'user_id' => $admin->id,
            'fcm_token' => str_repeat('a', 24),
            'device_name' => 'Admin Device',
            'device_type' => 'android',
            'last_active' => now(),
        ]);

        $user = User::factory()->create(['nomor_kk' => '5171018888888888']);
        UserDevice::query()->create([
            'user_id' => $user->id,
            'fcm_token' => str_repeat('b', 24),
            'device_name' => 'Jemaat Device',
            'device_type' => 'ios',
            'last_active' => now(),
        ]);

        $application = ServiceApplication::query()->create([
            'user_id' => $user->id,
            'nomor_kk_snapshot' => $user->nomor_kk,
            'category' => 'baptisan',
            'form_data' => ['nama_lengkap' => 'Anak A'],
            'attachments' => [],
            'status' => 'pending',
        ]);

        Sanctum::actingAs($admin);

        $response = $this->patchJson('/api/v1/services/applications/' . $application->id . '/status', [
            'status' => 'approved',
            'admin_note' => 'ok',
        ]);

        $response->assertOk()->assertJsonPath('data.status', 'approved');

        $this->assertDatabaseHas('notification_dispatch_logs', [
            'recipient_user_id' => $user->id,
            'module' => 'service_application',
            'event_type' => 'service_application_status_updated',
        ]);
    }

    public function test_admin_can_submit_service_for_jemaat_manually(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'nomor_kk' => '5171014444444444',
        ]);
        $jemaat = User::factory()->create([
            'role' => 'jemaat',
            'nomor_kk' => '5171015555555555',
        ]);

        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/services/apply', [
            'target_user_id' => $jemaat->id,
            'category' => 'permohonan_doa',
            'form_data' => [
                'pokok_doa' => 'Permohonan doa keluarga',
            ],
            'attachments' => [],
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.user_id', $jemaat->id)
            ->assertJsonPath('meta.submitted_by_admin', true)
            ->assertJsonPath('meta.target_user_id', $jemaat->id);
    }

    public function test_admin_can_edit_service_application_form_data(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $jemaat = User::factory()->create(['nomor_kk' => '5171016666666666']);

        $application = ServiceApplication::query()->create([
            'user_id' => $jemaat->id,
            'nomor_kk_snapshot' => $jemaat->nomor_kk,
            'category' => 'baptisan',
            'form_data' => [
                'nama_lengkap' => 'Nama Lama',
                'tanggal_lahir' => '2026-01-01',
            ],
            'attachments' => ['https://files/old.pdf'],
            'status' => 'pending',
        ]);

        Sanctum::actingAs($admin);

        $response = $this->patchJson('/api/v1/services/applications/' . $application->id, [
            'category' => 'baptisan',
            'form_data' => [
                'nama_lengkap' => 'Nama Baru',
                'tanggal_lahir' => '2026-02-02',
            ],
            'attachments' => ['https://files/new.pdf'],
        ]);

        $response->assertOk()
            ->assertJsonPath('data.category', 'baptisan')
            ->assertJsonPath('data.form_data.nama_lengkap', 'Nama Baru')
            ->assertJsonPath('data.form_data.tanggal_lahir', '2026-02-02');

        $this->assertDatabaseHas('service_applications', [
            'id' => $application->id,
            'category' => 'baptisan',
        ]);
    }

    public function test_select_field_in_template_validates_options_on_apply(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        $this->putJson('/api/v1/services/forms/permohonan_doa', [
            'category' => 'permohonan_doa',
            'name' => 'Form Permohonan Doa',
            'is_active' => true,
            'fields' => [
                [
                    'key' => 'jenis_permohonan',
                    'label' => 'Jenis Permohonan',
                    'type' => 'select',
                    'required' => true,
                    'options' => ['Kesehatan', 'Pekerjaan', 'Keluarga'],
                ],
            ],
        ])->assertOk();

        $jemaat = User::factory()->create(['nomor_kk' => '5171011212121212']);
        Sanctum::actingAs($jemaat);

        $invalid = $this->postJson('/api/v1/services/apply', [
            'category' => 'permohonan_doa',
            'form_data' => [
                'jenis_permohonan' => 'PilihanTidakValid',
            ],
        ]);

        $invalid->assertUnprocessable()->assertJsonPath('error_code', 'VALIDATION_ERROR');

        $valid = $this->postJson('/api/v1/services/apply', [
            'category' => 'permohonan_doa',
            'form_data' => [
                'jenis_permohonan' => 'Kesehatan',
            ],
        ]);

        $valid->assertCreated()->assertJsonPath('status', 'success');
    }

    public function test_jemaat_can_download_service_application_certificate_pdf(): void
    {
        $user = User::factory()->create(['nomor_kk' => '5171019999999999']);
        Sanctum::actingAs($user);

        $application = ServiceApplication::query()->create([
            'user_id' => $user->id,
            'nomor_kk_snapshot' => $user->nomor_kk,
            'category' => 'permohonan_doa',
            'form_data' => ['pokok_doa' => 'Doa damai sejahtera'],
            'attachments' => ['https://files.example.com/doa.txt'],
            'status' => 'approved',
        ]);

        $response = $this->get('/api/v1/services/applications/' . $application->id . '/certificate/pdf');

        $response->assertOk();
        $this->assertSame('application/pdf', $response->headers->get('content-type'));
    }
}
