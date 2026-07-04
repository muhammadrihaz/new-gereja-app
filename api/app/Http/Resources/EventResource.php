<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class EventResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $documentations = null;
        if ($this->relationLoaded('documentations')) {
            $documentations = $this->documentations->map(function ($doc): array {
                return [
                    'id' => $doc->id,
                    'file_name' => basename((string) $doc->file_path),
                    'mime_type' => (string) $doc->mime_type,
                    'file_size' => (int) $doc->file_size,
                    'url' => self::resolveStoredUrl((string) $doc->file_path),
                    'report_summary' => $doc->report_summary,
                    'created_at' => $doc->created_at?->toIso8601String(),
                ];
            })->values()->all();
        }

        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'date' => optional($this->date ?? $this->start_at)->toIso8601String(),
            'start_at' => optional($this->start_at)->toIso8601String(),
            'end_at' => optional($this->end_at)->toIso8601String(),
            'location' => $this->location,
            'category' => $this->category,
            'is_archived' => (bool) $this->is_archived,
            'archived_at' => optional($this->archived_at)->toIso8601String(),
            'is_expired' => $this->isExpiredSafe(),
            'created_by' => $this->created_by,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
            'documentation_count' => $this->relationLoaded('documentations')
                ? $this->documentations->count()
                : ($this->documentations_count ?? null),
            'documentations' => $documentations,
        ];
    }

    private function isExpiredSafe(): bool
    {
        $reference = $this->end_at ?? $this->start_at ?? $this->date;
        if ($reference === null) {
            return false;
        }
        return $reference->lessThan(now());
    }

    public static function resolveStoredUrl(string $path): ?string
    {
        if ($path === '') {
            return null;
        }
        // If already absolute
        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }
        try {
            return Storage::disk('public')->url($path);
        } catch (\Throwable) {
            return null;
        }
    }
}
