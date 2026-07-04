<?php

namespace Tests\Feature\Events;

use App\Models\Event;
use App\Models\EventDocumentation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class EventApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_event_categories_endpoint_returns_list(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/events/categories');

        $response->assertOk()->assertJsonPath('status', 'success');
        $response->assertJsonFragment(['code' => 'ibadah']);
    }

    public function test_admin_can_create_event(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/events', [
            'title' => 'Ibadah Raya',
            'description' => 'Deskripsi',
            'start_at' => now()->addDay()->setHour(9)->setMinute(0)->toIso8601String(),
            'end_at' => now()->addDay()->setHour(11)->setMinute(0)->toIso8601String(),
            'category' => 'ibadah',
            'location' => [
                'address' => 'Jl. Sunset Road',
                'latitude' => -8.670458,
                'longitude' => 115.212629,
            ],
        ]);

        $response->assertCreated()->assertJsonPath('status', 'success');
    }

    public function test_jemaat_cannot_create_event(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        $response = $this->postJson('/api/v1/events', [
            'title' => 'Ibadah Raya',
            'start_at' => now()->addDay()->setHour(9)->setMinute(0)->toIso8601String(),
            'end_at' => now()->addDay()->setHour(11)->setMinute(0)->toIso8601String(),
            'category' => 'ibadah',
            'location' => [
                'address' => 'Jl. Sunset Road',
                'latitude' => -8.670458,
                'longitude' => 115.212629,
            ],
        ]);

        $response->assertForbidden();
    }

    public function test_admin_can_upload_documentation(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $event = Event::factory()->create();
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/events/' . $event->id . '/documentation', [
            'files' => [UploadedFile::fake()->create('doc.jpg', 10, 'image/jpeg')],
            'report_summary' => 'Ringkas',
        ]);

        $response->assertCreated()->assertJsonPath('status', 'success');
    }

    public function test_documentation_download_success(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->create();
        Sanctum::actingAs($user);

        $relativePath = 'event-documentations/' . $event->id . '/file.jpg';
        $absolutePath = storage_path('app/' . $relativePath);

        if (! is_dir(dirname($absolutePath))) {
            mkdir(dirname($absolutePath), 0755, true);
        }

        file_put_contents($absolutePath, 'dummy-content');

        EventDocumentation::query()->create([
            'event_id' => $event->id,
            'file_path' => $relativePath,
            'mime_type' => 'image/jpeg',
            'file_size' => 12,
            'report_summary' => 'dummy',
        ]);

        $response = $this->get('/api/v1/events/' . $event->id . '/documentation/download');

        $response->assertOk();
        $this->assertSame('application/zip', $response->headers->get('content-type'));
    }

    public function test_members_cannot_see_archived_events(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        // Create one active future event and one archived event.
        Event::factory()->create([
            'title' => 'Ibadah Aktif',
            'start_at' => now()->addDays(2),
            'end_at' => now()->addDays(2)->addHours(2),
            'is_archived' => false,
        ]);
        Event::factory()->create([
            'title' => 'Ibadah Lampau',
            'start_at' => now()->subDays(10),
            'end_at' => now()->subDays(10)->addHours(2),
            'is_archived' => true,
            'archived_at' => now()->subDays(9),
        ]);

        $response = $this->getJson('/api/v1/events');
        $response->assertOk();

        $titles = collect($response->json('data'))->pluck('title')->all();
        $this->assertContains('Ibadah Aktif', $titles);
        $this->assertNotContains('Ibadah Lampau', $titles);
    }

    public function test_admin_can_query_archived_events(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        Event::factory()->create([
            'title' => 'Ibadah Aktif',
            'start_at' => now()->addDays(2),
            'end_at' => now()->addDays(2)->addHours(2),
            'is_archived' => false,
        ]);
        Event::factory()->create([
            'title' => 'Ibadah Lampau',
            'start_at' => now()->subDays(10),
            'end_at' => now()->subDays(10)->addHours(2),
            'is_archived' => true,
            'archived_at' => now()->subDays(9),
        ]);

        $response = $this->getJson('/api/v1/events?status=archived');
        $response->assertOk();
        $titles = collect($response->json('data'))->pluck('title')->all();
        $this->assertContains('Ibadah Lampau', $titles);
        $this->assertNotContains('Ibadah Aktif', $titles);
    }

    public function test_jemaat_forbidden_from_archive_filter(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        $response = $this->getJson('/api/v1/events?status=archived');
        $response->assertForbidden();
    }

    public function test_archive_command_moves_expired_events(): void
    {
        Event::factory()->create([
            'title' => 'Sudah Lewat',
            'start_at' => now()->subDays(3),
            'end_at' => now()->subDays(3)->addHour(),
            'is_archived' => false,
        ]);
        Event::factory()->create([
            'title' => 'Masih Aktif',
            'start_at' => now()->addDay(),
            'end_at' => now()->addDay()->addHour(),
            'is_archived' => false,
        ]);

        $this->artisan('events:archive-expired')->assertExitCode(0);

        $this->assertTrue(Event::where('title', 'Sudah Lewat')->first()->is_archived);
        $this->assertFalse(Event::where('title', 'Masih Aktif')->first()->is_archived);
    }

    public function test_event_search_filter_matches_title(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        Event::factory()->create([
            'title' => 'Doa Pagi Bersama',
            'start_at' => now()->addDay(),
            'end_at' => now()->addDay()->addHour(),
        ]);
        Event::factory()->create([
            'title' => 'Ibadah Raya',
            'start_at' => now()->addDay(),
            'end_at' => now()->addDay()->addHour(),
        ]);

        $response = $this->getJson('/api/v1/events?search=Doa');
        $response->assertOk();
        $titles = collect($response->json('data'))->pluck('title')->all();
        $this->assertContains('Doa Pagi Bersama', $titles);
        $this->assertNotContains('Ibadah Raya', $titles);
    }

    public function test_event_pagination_meta_present(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        Event::factory()->count(5)->create([
            'start_at' => now()->addDays(2),
            'end_at' => now()->addDays(2)->addHour(),
        ]);

        $response = $this->getJson('/api/v1/events?per_page=2');
        $response->assertOk();
        $meta = $response->json('meta');
        $this->assertNotNull($meta);
        $this->assertSame(2, $meta['per_page']);
        $this->assertGreaterThanOrEqual(5, $meta['total']);
        $this->assertGreaterThan(1, $meta['last_page']);
    }
}
