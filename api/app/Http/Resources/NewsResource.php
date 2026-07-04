<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NewsResource extends JsonResource
{
    /**
     * When true, resource is being used for a list endpoint; heavy fields like `content`
     * are omitted for performance and payload size.
     */
    public bool $listMode = false;

    public function toArray(Request $request): array
    {
        $payload = [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'excerpt' => $this->buildExcerpt(),
            'cover_image' => $this->normalizeCoverImage(),
            'published_at' => $this->published_at?->toIso8601String(),
            'created_by' => $this->created_by,
            'creator_name' => $this->relationLoaded('creator') ? $this->creator?->name : null,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
            'attachment_count' => $this->relationLoaded('attachments')
                ? $this->attachments->count()
                : ($this->attachments_count ?? $this->attachments()->count()),
        ];

        if (! $this->listMode) {
            $payload['content'] = $this->content;
        }

        if ($this->relationLoaded('attachments')) {
            $payload['attachments'] = $this->attachments->map(function ($att): array {
                return [
                    'id' => $att->id,
                    'file_name' => $att->file_name,
                    'mime_type' => $att->mime_type,
                    'file_size' => (int) $att->file_size,
                    'is_image' => str_starts_with((string) $att->mime_type, 'image/'),
                    'url' => EventResource::resolveStoredUrl((string) $att->file_path),
                ];
            })->values()->all();
        }

        return $payload;
    }

    private function buildExcerpt(): string
    {
        $desc = trim((string) $this->description);
        if ($desc !== '') {
            return mb_substr($desc, 0, 200);
        }
        $content = trim((string) $this->content);
        $plain = trim(preg_replace('/\s+/u', ' ', strip_tags($content)) ?? '');
        return mb_substr($plain, 0, 200);
    }

    private function normalizeCoverImage(): ?array
    {
        $raw = $this->cover_image;
        if (! is_array($raw)) {
            return null;
        }

        $url = (string) ($raw['url'] ?? '');
        $path = (string) ($raw['path'] ?? '');
        if ($url === '' && $path !== '') {
            $url = (string) (EventResource::resolveStoredUrl($path) ?? '');
        }

        return [
            'url' => $url !== '' ? $url : null,
            'path' => $path !== '' ? $path : null,
            'disk' => $raw['disk'] ?? null,
        ];
    }
}
