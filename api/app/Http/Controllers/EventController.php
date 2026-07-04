<?php

namespace App\Http\Controllers;

use App\Http\Requests\Events\StoreEventRequest;
use App\Http\Requests\Events\UploadDocumentationRequest;
use App\Http\Resources\EventResource;
use App\Models\Event;
use App\Models\EventCategory;
use App\Models\EventDocumentation;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;
use ZipArchive;

class EventController extends Controller
{
    use ApiResponse;

    public function categories(): JsonResponse
    {
        $categories = Cache::remember('event_categories.active', 600, function () {
            return EventCategory::query()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderBy('name')
                ->get(['code', 'name'])
                ->toArray();
        });

        return $this->successResponse($categories, 'Daftar kategori event berhasil diambil');
    }

    public function index(Request $request): JsonResponse
    {
        $actor = auth('sanctum')->user();
        $isAdmin = $actor && (string) $actor->role === 'admin';

        $status = strtolower((string) $request->query('status', ''));
        $search = trim((string) $request->query('search', ''));
        $category = trim((string) $request->query('category', ''));
        $perPage = max(1, min((int) $request->query('per_page', 15), 100));
        $sortBy = in_array($request->query('sort_by'), ['start_at', 'end_at', 'created_at', 'title'], true)
            ? $request->query('sort_by')
            : 'start_at';
        $sortOrder = strtolower((string) $request->query('sort_order')) === 'asc' ? 'asc' : 'desc';

        $query = Event::query()->withCount('documentations');

        // Members can never see archived events. Admin may filter.
        if (! $isAdmin) {
            $query->where('is_archived', false);
            // Members also cannot see events that ended.
            $cutoff = now();
            $query->where(function ($q) use ($cutoff): void {
                $q->whereNull('end_at')
                  ->orWhere('end_at', '>=', $cutoff);
            });
        }

        if ($category !== '') {
            $query->where('category', $category);
        }

        if ($search !== '') {
            $query->where(function ($q) use ($search): void {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // Status filter
        switch ($status) {
            case 'upcoming':
                $query->where('is_archived', false)
                      ->where(function ($q): void {
                          $q->where('start_at', '>=', now())
                            ->orWhere(function ($q2): void {
                                $q2->whereNull('start_at')->where('date', '>=', now());
                            });
                      });
                break;
            case 'ongoing':
                $query->where('is_archived', false)
                      ->where('start_at', '<=', now())
                      ->where(function ($q): void {
                          $q->whereNull('end_at')->orWhere('end_at', '>=', now());
                      });
                break;
            case 'past':
                $query->where(function ($q): void {
                    $q->where('end_at', '<', now())
                      ->orWhere(function ($q2): void {
                          $q2->whereNull('end_at')->where('start_at', '<', now());
                      });
                });
                break;
            case 'archived':
                if (! $isAdmin) {
                    return $this->errorResponse('Arsip event hanya dapat diakses oleh pegawai gereja', 'FORBIDDEN', 403);
                }
                $query->where('is_archived', true);
                break;
            case 'active':
            case '':
                // default: upcoming + ongoing, not archived
                if (! $isAdmin) {
                    // already restricted above
                }
                break;
            case 'all':
                // admin-only pass-through
                break;
        }

        $events = $query->orderBy($sortBy, $sortOrder)->paginate($perPage)->withQueryString();

        return $this->successResponse(
            EventResource::collection($events->items()),
            'Daftar event berhasil diambil',
            200,
            [
                'meta' => [
                    'current_page' => $events->currentPage(),
                    'per_page' => $events->perPage(),
                    'total' => $events->total(),
                    'last_page' => $events->lastPage(),
                    'has_more' => $events->hasMorePages(),
                ],
                'links' => [
                    'first' => $events->url(1),
                    'last' => $events->url($events->lastPage()),
                    'prev' => $events->previousPageUrl(),
                    'next' => $events->nextPageUrl(),
                ],
            ]
        );
    }

    public function store(StoreEventRequest $request): JsonResponse
    {
        $startAt = $request->date('start_at') ?: $request->date('date');
        $endAt = $request->date('end_at');
        $location = $this->normalizeLocation($request->input('location'));

        $event = Event::query()->create([
            'title' => $request->string('title')->toString(),
            'description' => $request->string('description')->toString() ?: null,
            'date' => $startAt,
            'start_at' => $startAt,
            'end_at' => $endAt,
            'location' => $location,
            'category' => $request->string('category')->toString(),
            'created_by' => auth('sanctum')->id(),
        ]);

        return $this->successResponse(new EventResource($event->loadCount('documentations')), 'Event berhasil dibuat', 201);
    }

    public function update(StoreEventRequest $request, Event $event): JsonResponse
    {
        $startAt = $request->date('start_at') ?: $request->date('date');
        $endAt = $request->date('end_at');
        $location = $this->normalizeLocation($request->input('location'));

        $event->update([
            'title' => $request->string('title')->toString(),
            'description' => $request->string('description')->toString() ?: null,
            'date' => $startAt,
            'start_at' => $startAt,
            'end_at' => $endAt,
            'location' => $location,
            'category' => $request->string('category')->toString(),
        ]);

        // If admin updates end_at to be in the future, revive from archive
        if ($event->is_archived && $endAt !== null && $endAt->isFuture()) {
            $event->update(['is_archived' => false, 'archived_at' => null]);
        }

        return $this->successResponse(new EventResource($event->fresh()->loadCount('documentations')), 'Event berhasil diperbarui');
    }

    public function uploadDocumentation(UploadDocumentationRequest $request, Event $event): JsonResponse
    {
        $files = $request->file('files', []);
        $totalSize = collect($files)->sum(fn($file) => $file->getSize());

        if ($totalSize > (200 * 1024 * 1024)) {
            return $this->errorResponse('Total upload melebihi 200MB', 'VALIDATION_ERROR', 422, [
                'files' => ['Total ukuran file maksimal 200MB per request.'],
            ]);
        }

        $stored = [];
        foreach ($files as $file) {
            // Store on the public disk so files are downloadable & previewable via public URL
            $storedPath = $file->store("event-documentations/{$event->id}", 'public');

            $doc = EventDocumentation::query()->create([
                'event_id' => $event->id,
                'file_path' => $storedPath,
                'mime_type' => (string) $file->getMimeType(),
                'file_size' => (int) $file->getSize(),
                'report_summary' => $request->string('report_summary')->toString() ?: null,
            ]);
            $stored[] = [
                'id' => $doc->id,
                'file_name' => basename($storedPath),
                'mime_type' => $doc->mime_type,
                'file_size' => $doc->file_size,
                'url' => EventResource::resolveStoredUrl($storedPath),
            ];
        }

        return $this->successResponse($stored, 'Dokumentasi berhasil diunggah', 201);
    }

    public function downloadDocumentation(Event $event)
    {
        $docs = $event->documentations()->get();

        if ($docs->isEmpty()) {
            return $this->errorResponse('Dokumentasi event tidak ditemukan', 'NOT_FOUND', 404);
        }

        $zipPath = storage_path("app/temp/event-{$event->id}-documentation.zip");

        if (! is_dir(dirname($zipPath))) {
            mkdir(dirname($zipPath), 0755, true);
        }

        $zip = new ZipArchive();
        $zip->open($zipPath, ZipArchive::CREATE | ZipArchive::OVERWRITE);

        foreach ($docs as $doc) {
            $absolutePath = $this->resolveStoredAbsolutePath($doc->file_path);
            if ($absolutePath !== null && file_exists($absolutePath)) {
                $zip->addFile($absolutePath, basename($doc->file_path));
            }
        }

        $zip->close();

        return response()->download($zipPath, "event-{$event->id}-documentation.zip", [
            'Content-Type' => 'application/zip',
        ])->deleteFileAfterSend(true);
    }

    /**
     * Try to resolve a stored file path to an absolute filesystem path.
     * Handles both public and private (default) disks, including Laravel 11+
     * private disk path convention (storage/app/private/*).
     */
    private function resolveStoredAbsolutePath(string $relative): ?string
    {
        if ($relative === '') {
            return null;
        }
        foreach (['public', 'local'] as $disk) {
            try {
                if (Storage::disk($disk)->exists($relative)) {
                    return Storage::disk($disk)->path($relative);
                }
            } catch (\Throwable) {
                // ignore missing disks
            }
        }
        // Legacy fallbacks
        foreach ([
            storage_path('app/private/' . ltrim($relative, '/')),
            storage_path('app/public/' . ltrim($relative, '/')),
            storage_path('app/' . ltrim($relative, '/')),
        ] as $candidate) {
            if (file_exists($candidate)) {
                return $candidate;
            }
        }
        return null;
    }

    public function destroy(Event $event): JsonResponse
    {
        // Delete related documentation and attachments from disk
        $event->documentations()->get()->each(function ($doc): void {
            $path = $this->resolveStoredAbsolutePath($doc->file_path);
            if ($path !== null && file_exists($path)) {
                @unlink($path);
            }
        });

        $event->delete();

        return $this->successResponse(null, 'Event berhasil dihapus');
    }

    private function normalizeLocation(mixed $location): array
    {
        if (is_string($location)) {
            return [
                'address' => $location,
                'latitude' => null,
                'longitude' => null,
            ];
        }
        if (is_array($location)) {
            return $location;
        }
        return [
            'address' => null,
            'latitude' => null,
            'longitude' => null,
        ];
    }
}
