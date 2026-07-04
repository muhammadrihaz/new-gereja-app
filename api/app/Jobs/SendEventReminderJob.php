<?php

namespace App\Jobs;

use App\Models\Event;
use App\Models\NotificationDispatchLog;
use App\Services\NotificationTargetingService;
use App\Services\PushNotificationService;
use Carbon\Carbon;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendEventReminderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public int $eventId,
        public string $eventType
    ) {}

    public function handle(NotificationTargetingService $targeting, PushNotificationService $notifications): void
    {
        $event = Event::query()->find($this->eventId);
        if (! $event) {
            return;
        }

        if (! $this->shouldSendReminder($event->id, $this->eventType)) {
            return;
        }

        $targets = $targeting->resolveTargetDevices('event_attendees');
        if ($targets === []) {
            return;
        }

        $startAt = $this->resolveEventStart($event);
        [$title, $message] = $this->buildMessage($event, $startAt, $this->eventType);

        $notifications->notifyDevices(
            $targets,
            $title,
            $message,
            'events',
            $this->eventType,
            null,
            [
                'event_id' => $event->id,
                'start_at' => $startAt->toIso8601String(),
            ]
        );
    }

    private function resolveEventStart(Event $event): Carbon
    {
        $startAt = $event->start_at ?? $event->date;
        return $startAt instanceof Carbon ? $startAt : Carbon::parse($startAt);
    }

    private function buildMessage(Event $event, Carbon $startAt, string $eventType): array
    {
        if ($eventType === 'event_reminder_1h') {
            return [
                'Ibadah mulai 1 jam lagi',
                sprintf(
                    '%s akan dimulai pada %s. Sampai jumpa di gereja!',
                    $event->title,
                    $startAt->format('H:i')
                ),
            ];
        }

        return [
            'Pengingat Ibadah & Event',
            sprintf(
                '%s akan dimulai pada %s. Jangan lewatkan ya!',
                $event->title,
                $startAt->format('d M Y, H:i')
            ),
        ];
    }

    private function shouldSendReminder(int $eventId, string $eventType): bool
    {
        return ! NotificationDispatchLog::query()
            ->where('module', 'events')
            ->where('event_type', $eventType)
            ->where('context->event_id', $eventId)
            ->exists();
    }
}
