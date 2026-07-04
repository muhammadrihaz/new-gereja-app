<?php

namespace Tests\Feature\Users;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UserApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_get_families_grouped_by_nomor_kk(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        User::factory()->create([
            'role' => 'jemaat',
            'name' => 'Ayu',
            'username' => 'ayu01',
            'nomor_kk' => '5171011111111111',
        ]);
        User::factory()->create([
            'role' => 'jemaat',
            'name' => 'Budi',
            'username' => 'budi01',
            'nomor_kk' => '5171011111111111',
        ]);
        User::factory()->create([
            'role' => 'jemaat',
            'name' => 'Citra',
            'username' => 'citra01',
            'nomor_kk' => '5171012222222222',
        ]);

        Sanctum::actingAs($admin);

        $response = $this->getJson('/api/v1/users/families?per_page=10');

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('data.0.nomor_kk', '5171011111111111')
            ->assertJsonPath('data.0.total_members', 2);
    }

    public function test_admin_can_search_families_by_member_name_or_nomor_kk(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        User::factory()->create([
            'role' => 'jemaat',
            'name' => 'Daniel',
            'username' => 'daniel01',
            'nomor_kk' => '5171013333333333',
        ]);
        User::factory()->create([
            'role' => 'jemaat',
            'name' => 'Erika',
            'username' => 'erika01',
            'nomor_kk' => '5171014444444444',
        ]);

        Sanctum::actingAs($admin);

        $byName = $this->getJson('/api/v1/users/families?search=Daniel');
        $byName->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.nomor_kk', '5171013333333333');

        $byKk = $this->getJson('/api/v1/users/families?search=444444');
        $byKk->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.nomor_kk', '5171014444444444');
    }

    public function test_jemaat_cannot_access_families_endpoint(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        $this->getJson('/api/v1/users/families')->assertForbidden();
    }
}
