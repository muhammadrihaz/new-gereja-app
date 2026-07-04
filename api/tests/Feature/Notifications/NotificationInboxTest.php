<?php

namespace Tests\Feature\Notifications;

use App\Models\NotificationDispatchLog;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationInboxTest extends TestCase
{
    use RefreshDatabase;

    private function seedLog(int $userId, array $overrides = []): NotificationDispatchLog
    {
        return NotificationDispatchLog::query()->create(array_merge([
            'sender_user_id' => null,
            'recipient_user_id' => $userId,
            'fcm_token' => 'token-' . uniqid(),
            'module' => 'broadcast',
            'event_type' => 'admin_broadcast',
            'title' => 'Info Jemaat',
            'message' => 'Halo Jemaat, ada info baru!',
            'context' => ['x' => 1],
            'status' => 'sent',
            'provider' => 'fcm_v1',
            'trace_id' => 'trace-' . uniqid(),
            'provider_response' => ['http_status' => 200],
        ], $overrides));
    }

    public function test_user_can_list_inbox_notifications(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->seedLog($user->id, ['title' => 'Satu']);
        $this->seedLog($user->id, ['title' => 'Dua']);
        // Another user's notification should NOT leak.
        $other = User::factory()->create();
        $this->seedLog($other->id, ['title' => 'Bukan Saya']);

        $response = $this->getJson('/api/v1/notifications/inbox');
        $response->assertOk();
        $titles = collect($response->json('data'))->pluck('title')->all();
        $this->assertContains('Satu', $titles);
        $this->assertContains('Dua', $titles);
        $this->assertNotContains('Bukan Saya', $titles);
    }

    public function test_unread_count_returns_correct_number(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->seedLog($user->id, ['read_at' => null]);
        $this->seedLog($user->id, ['read_at' => null]);
        $this->seedLog($user->id, ['read_at' => now()]);

        $response = $this->getJson('/api/v1/notifications/unread-count');
        $response->assertOk();
        $this->assertSame(2, $response->json('data.count'));
    }

    public function test_email_only_dispatch_logs_are_excluded(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->seedLog($user->id, ['provider' => 'email', 'read_at' => null]);
        $this->seedLog($user->id, ['provider' => 'fcm_v1', 'read_at' => null]);

        $response = $this->getJson('/api/v1/notifications/unread-count');
        $response->assertOk();
        $this->assertSame(1, $response->json('data.count'));
    }

    public function test_user_can_mark_single_notification_read(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $log = $this->seedLog($user->id, ['read_at' => null]);

        $response = $this->patchJson('/api/v1/notifications/' . $log->id . '/read');
        $response->assertOk();

        $this->assertNotNull($log->fresh()->read_at);
    }

    public function test_user_cannot_mark_others_notification_read(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        Sanctum::actingAs($user);

        $log = $this->seedLog($other->id, ['read_at' => null]);

        $response = $this->patchJson('/api/v1/notifications/' . $log->id . '/read');
        $response->assertForbidden();
        $this->assertNull($log->fresh()->read_at);
    }

    public function test_mark_all_read_updates_all_unread(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->seedLog($user->id, ['read_at' => null]);
        $this->seedLog($user->id, ['read_at' => null]);
        $this->seedLog($user->id, ['read_at' => now()]);

        $response = $this->patchJson('/api/v1/notifications/read-all');
        $response->assertOk();
        $this->assertSame(2, $response->json('data.updated'));

        $this->assertSame(0, NotificationDispatchLog::where('recipient_user_id', $user->id)
            ->whereNull('read_at')->count());
    }
}
