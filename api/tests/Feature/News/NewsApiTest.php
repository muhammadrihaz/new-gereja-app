<?php

namespace Tests\Feature\News;

use App\Models\News;
use App\Models\NewsAttachment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NewsApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_list_news(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        News::factory()->count(3)->create();

        $response = $this->getJson('/api/v1/news');

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure([
                'status',
                'message',
                'data' => [],
                'meta' => ['current_page', 'per_page', 'total', 'last_page'],
            ]);
    }

    public function test_authenticated_user_can_show_news(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $news = News::factory()->create();

        $response = $this->getJson('/api/v1/news/' . $news->id);

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.id', $news->id)
            ->assertJsonPath('data.title', $news->title);
    }

    public function test_admin_can_create_news(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/news', [
            'title' => 'Ibadah Raya GPI Yehuda',
            'description' => 'Ringkasan singkat ibadah raya',
            'content' => 'Ini adalah isi berita lengkap tentang ibadah raya GPI Yehuda. Puji Tuhan.',
            'published_at' => now()->toIso8601String(),
        ]);

        $response->assertCreated()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.title', 'Ibadah Raya GPI Yehuda');

        $this->assertDatabaseHas('news', [
            'title' => 'Ibadah Raya GPI Yehuda',
        ]);
    }

    public function test_jemaat_cannot_create_news(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        $response = $this->postJson('/api/v1/news', [
            'title' => 'Ibadah Raya',
            'content' => 'Konten berita.',
        ]);

        $response->assertForbidden();
    }

    public function test_admin_can_update_news(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        $news = News::factory()->create();

        $response = $this->putJson('/api/v1/news/' . $news->id, [
            'title' => 'Judul Diperbarui',
            'content' => 'Konten diperbarui.',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.title', 'Judul Diperbarui');

        $this->assertDatabaseHas('news', [
            'id' => $news->id,
            'title' => 'Judul Diperbarui',
        ]);
    }

    public function test_jemaat_cannot_update_news(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        $news = News::factory()->create();

        $response = $this->putJson('/api/v1/news/' . $news->id, [
            'title' => 'Tidak Boleh',
            'content' => 'Tidak boleh edit.',
        ]);

        $response->assertForbidden();
    }

    public function test_admin_can_delete_news(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        $news = News::factory()->create();

        $response = $this->deleteJson('/api/v1/news/' . $news->id);

        $response->assertOk();
        $this->assertDatabaseMissing('news', ['id' => $news->id]);
    }

    public function test_jemaat_cannot_delete_news(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        $news = News::factory()->create();

        $response = $this->deleteJson('/api/v1/news/' . $news->id);
        $response->assertForbidden();
    }

    public function test_admin_can_upload_attachments(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $news = News::factory()->create();
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/news/' . $news->id . '/attachments', [
            'files' => [
                UploadedFile::fake()->create('foto1.jpg', 50, 'image/jpeg'),
                UploadedFile::fake()->create('dokumen.pdf', 100, 'application/pdf'),
            ],
        ]);

        $response->assertCreated()
            ->assertJsonPath('status', 'success');

        $this->assertCount(2, $news->fresh()->attachments);
    }

    public function test_jemaat_cannot_upload_attachments(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        $news = News::factory()->create();
        Sanctum::actingAs($jemaat);

        $response = $this->postJson('/api/v1/news/' . $news->id . '/attachments', [
            'files' => [
                UploadedFile::fake()->create('foto.jpg', 50, 'image/jpeg'),
            ],
        ]);

        $response->assertForbidden();
    }

    public function test_authenticated_user_can_download_attachments(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $news = News::factory()->create();

        Sanctum::actingAs($admin);
        $uploadResponse = $this->post('/api/v1/news/' . $news->id . '/attachments', [
            'files' => [
                UploadedFile::fake()->create('foto.jpg', 100, 'image/jpeg'),
            ],
        ]);
        $uploadResponse->assertCreated();
        $this->assertCount(1, $news->fresh()->attachments);

        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->get('/api/v1/news/' . $news->id . '/attachments/download');
        $response->assertOk();
        $this->assertStringContainsString('application/zip', $response->headers->get('Content-Type') ?? '');
    }

    public function test_download_attachments_returns_404_when_empty(): void
    {
        $user = User::factory()->create();
        $news = News::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/news/' . $news->id . '/attachments/download');

        $response->assertStatus(404);
    }

    public function test_news_list_includes_attachment_count(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $news = News::factory()->create();
        NewsAttachment::factory()->count(3)->create([
            'news_id' => $news->id,
        ]);

        $response = $this->getJson('/api/v1/news');

        $response->assertOk();
        $this->assertEquals(3, $response->json('data.0.attachment_count'));
    }

    public function test_create_news_validates_required_fields(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/news', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['title', 'content']);
    }

    public function test_news_is_ordered_by_published_at_desc(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $older = News::factory()->create(['published_at' => now()->subDays(5)]);
        $newer = News::factory()->create(['published_at' => now()->subDay()]);

        $response = $this->getJson('/api/v1/news');

        $response->assertOk();
        $this->assertEquals($newer->id, $response->json('data.0.id'));
        $this->assertEquals($older->id, $response->json('data.1.id'));
    }

    public function test_news_list_search_filter(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        News::factory()->create(['title' => 'Pengumuman Baptisan Massal', 'published_at' => now()->subDay()]);
        News::factory()->create(['title' => 'Ibadah Raya', 'published_at' => now()->subDay()]);

        $response = $this->getJson('/api/v1/news?search=Baptisan');
        $response->assertOk();
        $titles = collect($response->json('data'))->pluck('title')->all();
        $this->assertContains('Pengumuman Baptisan Massal', $titles);
        $this->assertNotContains('Ibadah Raya', $titles);
    }

    public function test_news_detail_includes_attachments_array(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $news = News::factory()->create();
        NewsAttachment::factory()->count(2)->create([
            'news_id' => $news->id,
            'mime_type' => 'image/jpeg',
        ]);

        $response = $this->getJson('/api/v1/news/' . $news->id);
        $response->assertOk();

        $attachments = $response->json('data.attachments');
        $this->assertIsArray($attachments);
        $this->assertCount(2, $attachments);
        $this->assertArrayHasKey('is_image', $attachments[0]);
        $this->assertTrue($attachments[0]['is_image']);
    }

    public function test_news_list_hides_content_field_for_performance(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        News::factory()->create(['published_at' => now()->subDay()]);

        $response = $this->getJson('/api/v1/news');
        $response->assertOk();
        $first = $response->json('data.0');
        $this->assertArrayHasKey('excerpt', $first);
        $this->assertArrayNotHasKey('content', $first);
    }

    public function test_news_list_hides_unpublished_from_default_list(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        News::factory()->create(['title' => 'Draft belum publish', 'published_at' => null]);
        News::factory()->create(['title' => 'Sudah terbit', 'published_at' => now()->subDay()]);

        $response = $this->getJson('/api/v1/news');
        $response->assertOk();
        $titles = collect($response->json('data'))->pluck('title')->all();
        $this->assertContains('Sudah terbit', $titles);
        $this->assertNotContains('Draft belum publish', $titles);
    }
}
