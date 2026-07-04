<?php

namespace App\Http\Controllers;

use App\Http\Requests\News\StoreNewsRequest;
use App\Http\Requests\News\UpdateNewsRequest;
use App\Http\Requests\News\UploadNewsAttachmentsRequest;
use App\Http\Resources\NewsResource;
use App\Models\News;
use App\Models\NewsAttachment;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use ZipArchive;

class NewsController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $perPage = max(1, min((int) $request->query('per_page', 15), 100));
        $search = trim((string) $request->query('search', ''));
        $publishedOnly = filter_var($request->query('published_only', true), FILTER_VALIDATE_BOOL);

        $query = News::query()
            ->with('creator')
            ->withCount('attachments');

        if ($publishedOnly) {
            $query->whereNotNull('published_at')->where('published_at', '<=', now());
        }

        if ($search !== '') {
            $query->where(function ($q) use ($search): void {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%")
                  ->orWhere('content', 'like', "%{$search}%");
            });
        }

        $news = $query
            ->orderBy('published_at', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate($perPage)
            ->withQueryString();

        $items = collect($news->items())->map(function (News $n) use ($request): array {
            $resource = new NewsResource($n);
            $resource->listMode = true;

            return $resource->toArray($request);
        })->values()->all();

        return $this->successResponse(
            $items,
            'Daftar berita berhasil diambil',
            200,
            [
                'meta' => [
                    'current_page' => $news->currentPage(),
                    'per_page' => $news->perPage(),
                    'total' => $news->total(),
                    'last_page' => $news->lastPage(),
                    'has_more' => $news->hasMorePages(),
                ],
                'links' => [
                    'first' => $news->url(1),
                    'last' => $news->url($news->lastPage()),
                    'prev' => $news->previousPageUrl(),
                    'next' => $news->nextPageUrl(),
                ],
            ]
        );
    }

    public function show(News $news): JsonResponse
    {
        $news->load(['creator', 'attachments']);
        return $this->successResponse(new NewsResource($news), 'Berita berhasil diambil');
    }

    public function store(StoreNewsRequest $request): JsonResponse
    {
        $coverImage = $request->input('cover_image');
        
        if ($request->hasFile('cover_file')) {
            $path = $request->file('cover_file')->store('news-covers', 'public');
            $coverImage = [
                'url' => \App\Http\Resources\EventResource::resolveStoredUrl($path),
                'disk' => 'public',
                'path' => $path,
            ];
        }

        $news = News::query()->create([
            'title' => $request->string('title')->toString(),
            'description' => $request->string('description')->toString() ?: null,
            'content' => $request->string('content')->toString(),
            'cover_image' => $coverImage,
            'created_by' => auth('sanctum')->id(),
            'published_at' => $request->date('published_at') ?? now(),
            'kegiatan_date' => $request->date('kegiatan_date'),
        ]);

        return $this->successResponse(new NewsResource($news->load(['creator', 'attachments'])), 'Berita berhasil dibuat', 201);
    }

    public function update(UpdateNewsRequest $request, News $news): JsonResponse
    {
        $data = $request->only(['title', 'description', 'content', 'published_at', 'kegiatan_date']);
        
        $coverImage = $request->input('cover_image');
        if ($request->hasFile('cover_file')) {
            // Delete old cover if exists
            if (is_array($news->cover_image) && !empty($news->cover_image['path'])) {
                $this->deleteStoredFile($news->cover_image['path']);
            }
            
            $path = $request->file('cover_file')->store('news-covers', 'public');
            $coverImage = [
                'url' => \App\Http\Resources\EventResource::resolveStoredUrl($path),
                'disk' => 'public',
                'path' => $path,
            ];
            $data['cover_image'] = $coverImage;
        } elseif ($request->has('cover_image')) {
            $data['cover_image'] = $coverImage;
        }

        $news->update($data);

        return $this->successResponse(new NewsResource($news->fresh()->load(['creator', 'attachments'])), 'Berita berhasil diperbarui');
    }

    public function destroy(News $news): JsonResponse
    {
        // Clean up attachments from storage to avoid orphan files.
        $news->attachments()->get()->each(function (NewsAttachment $att): void {
            $this->deleteStoredFile((string) $att->file_path);
        });
        $news->delete();

        return $this->successResponse(null, 'Berita berhasil dihapus');
    }

    public function uploadAttachments(UploadNewsAttachmentsRequest $request, News $news): JsonResponse
    {
        $files = $request->file('files', []);

        $uploaded = [];
        foreach ($files as $file) {
            // Store on `public` disk so files can be accessed via public URL for gallery.
            $storedPath = $file->store("news-attachments/{$news->id}", 'public');

            $attachment = NewsAttachment::query()->create([
                'news_id' => $news->id,
                'file_path' => $storedPath,
                'file_name' => $file->getClientOriginalName(),
                'mime_type' => (string) $file->getMimeType(),
                'file_size' => (int) $file->getSize(),
            ]);

            $uploaded[] = [
                'id' => $attachment->id,
                'file_name' => $attachment->file_name,
                'mime_type' => $attachment->mime_type,
                'file_size' => $attachment->file_size,
                'is_image' => str_starts_with((string) $attachment->mime_type, 'image/'),
                'url' => \App\Http\Resources\EventResource::resolveStoredUrl($storedPath),
            ];
        }

        return $this->successResponse($uploaded, 'Lampiran berhasil diunggah', 201);
    }

    public function downloadAttachments(News $news)
    {
        $attachments = $news->attachments()->get();

        if ($attachments->isEmpty()) {
            return $this->errorResponse('Lampiran berita tidak ditemukan', 'NOT_FOUND', 404);
        }

        $zipPath = storage_path("app/temp/news-{$news->id}-attachments.zip");

        if (! is_dir(dirname($zipPath))) {
            mkdir(dirname($zipPath), 0755, true);
        }

        $zip = new ZipArchive();
        $zip->open($zipPath, ZipArchive::CREATE | ZipArchive::OVERWRITE);

        foreach ($attachments as $att) {
            $absolutePath = $this->resolveStoredAbsolutePath((string) $att->file_path);
            if ($absolutePath !== null && file_exists($absolutePath)) {
                $zip->addFile($absolutePath, $att->file_name);
            }
        }

        $zip->close();

        return response()->download($zipPath, "berita-{$news->id}-lampiran.zip", [
            'Content-Type' => 'application/zip',
        ])->deleteFileAfterSend(true);
    }

    /**
     * Resolve a stored file relative path to an absolute filesystem path, transparently
     * handling public/private disks and Laravel 11+ private disk convention.
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
            }
        }
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

    private function deleteStoredFile(string $relative): void
    {
        if ($relative === '') {
            return;
        }
        foreach (['public', 'local'] as $disk) {
            try {
                if (Storage::disk($disk)->exists($relative)) {
                    Storage::disk($disk)->delete($relative);
                    return;
                }
            } catch (\Throwable) {
            }
        }
    }
}
