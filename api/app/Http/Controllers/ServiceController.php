<?php

namespace App\Http\Controllers;

use App\Http\Requests\Services\ApplyServiceRequest;
use App\Http\Requests\Services\UpdateServiceApplicationRequest;
use App\Http\Requests\Services\UpsertServiceFormTemplateRequest;
use App\Http\Requests\Services\UpdateServiceStatusRequest;
use App\Models\ServiceApplication;
use App\Models\ServiceCategory;
use App\Models\ServiceFormTemplate;
use App\Models\User;
use App\Services\PushNotificationService;
use App\Support\ApiResponse;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Validator;

class ServiceController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly PushNotificationService $pushNotificationService) {}

    public function applications(Request $request): JsonResponse
    {
        $actor = auth('sanctum')->user();

        $status = trim((string) $request->query('status', ''));
        $category = trim((string) $request->query('category', ''));
        $search = trim((string) $request->query('search', ''));
        $perPage = max(1, min((int) $request->query('per_page', 20), 100));

        $query = ServiceApplication::query()->with('user:id,name,username,email,role');

        if ((string) optional($actor)->role !== 'admin') {
            $query->where('user_id', optional($actor)->id);
        }

        if ($status !== '') {
            $query->where('status', $status);
        }
        if ($category !== '') {
            $query->where('category', $category);
        }
        if ($search !== '') {
            $query->whereHas('user', function ($q) use ($search): void {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('username', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $applications = $query
            ->latest('id')
            ->paginate($perPage)
            ->withQueryString();

        return $this->successResponse(
            $applications->items(),
            'Daftar pengajuan layanan berhasil diambil',
            200,
            [
                'meta' => [
                    'current_page' => $applications->currentPage(),
                    'per_page' => $applications->perPage(),
                    'total' => $applications->total(),
                    'last_page' => $applications->lastPage(),
                    'has_more' => $applications->hasMorePages(),
                ],
            ]
        );
    }

    public function categories(): JsonResponse
    {
        $categories = Cache::remember('service_categories.active', 600, function () {
            return ServiceCategory::query()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderBy('name')
                ->get(['code', 'name'])
                ->toArray();
        });

        return $this->successResponse($categories, 'Daftar kategori layanan berhasil diambil');
    }

    public function templates(): JsonResponse
    {
        $templates = Cache::remember('service_templates.all', 600, function () {
            return ServiceFormTemplate::query()
                ->orderBy('category')
                ->get(['id', 'category', 'name', 'fields', 'is_active'])
                ->toArray();
        });

        return $this->successResponse($templates, 'Daftar template layanan berhasil diambil');
    }

    public function showTemplate(string $category): JsonResponse
    {
        $cacheKey = 'service_templates.' . $category;
        $template = Cache::remember($cacheKey, 600, function () use ($category) {
            $row = ServiceFormTemplate::query()
                ->where('category', $category)
                ->first();
            return $row ? $row->toArray() : null;
        });

        if (! $template) {
            return $this->errorResponse('Template layanan tidak ditemukan', 'NOT_FOUND', 404);
        }

        return $this->successResponse($template, 'Template layanan berhasil diambil');
    }

    public function apply(ApplyServiceRequest $request): JsonResponse
    {
        /** @var User|null $actor */
        $actor = auth('sanctum')->user();
        $targetUser = $actor;

        if (! $actor) {
            return $this->errorResponse('Unauthorized', 'UNAUTHORIZED', 401);
        }

        if ((string) $actor->role === 'admin' && $request->filled('target_user_id')) {
            $targetUser = User::query()->find($request->integer('target_user_id'));

            if (! $targetUser) {
                return $this->errorResponse('Jemaat target tidak ditemukan', 'NOT_FOUND', 404, [
                    'target_user_id' => ['User target tidak ditemukan.'],
                ]);
            }
        }

        if (! $targetUser || ! is_string($targetUser->nomor_kk) || trim($targetUser->nomor_kk) === '') {
            return $this->errorResponse('Nomor KK wajib tersedia pada profil jemaat untuk pendaftaran layanan', 'VALIDATION_ERROR', 422, [
                'nomor_kk' => ['Nomor KK wajib diisi pada profil sebelum mengajukan layanan.'],
            ]);
        }

        $template = ServiceFormTemplate::query()
            ->where('category', $request->string('category')->toString())
            ->where('is_active', true)
            ->first();

        if (! $template) {
            return $this->errorResponse('Kategori layanan tidak tersedia', 'VALIDATION_ERROR', 422, [
                'category' => ['Kategori layanan tidak tersedia atau belum aktif.'],
            ]);
        }

        $formData = $request->input('form_data', []);
        $dynamicRules = [];

        foreach ($template->fields as $field) {
            $key = $field['key'] ?? null;
            $type = $field['type'] ?? 'string';
            $required = (bool) ($field['required'] ?? false);

            if (! is_string($key) || $key === '') {
                continue;
            }

            $rules = [$required ? 'required' : 'nullable'];

            if ($type === 'string') {
                $rules[] = 'string';
            }

            if ($type === 'date') {
                $rules[] = 'date';
            }

            if ($type === 'number') {
                $rules[] = 'numeric';
            }

            if ($type === 'boolean') {
                $rules[] = 'boolean';
            }

            if ($type === 'select') {
                $rules[] = 'string';
                $options = collect($field['options'] ?? [])
                    ->map(fn($opt) => is_scalar($opt) ? (string) $opt : null)
                    ->filter(fn($opt) => is_string($opt) && $opt !== '')
                    ->values()
                    ->all();

                if ($options !== []) {
                    $rules[] = Rule::in($options);
                }
            }

            $dynamicRules[$key] = $rules;
        }

        $validator = Validator::make($formData, $dynamicRules);

        if ($validator->fails()) {
            return $this->errorResponse('Validasi gagal', 'VALIDATION_ERROR', 422, $validator->errors()->toArray());
        }

        $application = ServiceApplication::query()->create([
            'user_id' => $targetUser->id,
            'nomor_kk_snapshot' => $targetUser->nomor_kk,
            'category' => $request->string('category')->toString(),
            'form_data' => $formData,
            'attachments' => $request->input('attachments', []),
            'status' => 'pending',
        ]);

        $adminIds = User::query()
            ->where('role', 'admin')
            ->pluck('id')
            ->all();

        $this->pushNotificationService->notifyUsers(
            $adminIds,
            'Pengajuan layanan baru',
            "Jemaat {$targetUser->username} mengajukan layanan {$application->category}.",
            'service_application',
            'service_application_submitted',
            $actor->id,
            [
                'application_id' => $application->id,
                'category' => $application->category,
                'status' => $application->status,
            ]
        );

        return $this->successResponse($application, 'Pendaftaran layanan berhasil dikirim', 201, [
            'meta' => [
                'submitted_by_admin' => (string) $actor->role === 'admin' && (int) $actor->id !== (int) $targetUser->id,
                'target_user_id' => $targetUser->id,
            ],
        ]);
    }

    public function upsertTemplate(UpsertServiceFormTemplateRequest $request, ?string $category = null): JsonResponse
    {
        $targetCategory = $category ?: $request->string('category')->toString();

        if ($category !== null && $request->string('category')->toString() !== '' && $request->string('category')->toString() !== $category) {
            return $this->errorResponse('Category pada path dan body tidak sama', 'VALIDATION_ERROR', 422, [
                'category' => ['Category body harus sama dengan category path.'],
            ]);
        }

        $categoryExists = ServiceCategory::query()
            ->where('code', $targetCategory)
            ->where('is_active', true)
            ->exists();

        if (! $categoryExists) {
            return $this->errorResponse('Kategori layanan tidak tersedia', 'VALIDATION_ERROR', 422, [
                'category' => ['Kategori harus dipilih dari daftar kategori layanan aktif.'],
            ]);
        }

        foreach ($request->input('fields', []) as $index => $field) {
            $type = $field['type'] ?? 'string';
            $options = collect($field['options'] ?? [])
                ->map(fn($opt) => is_scalar($opt) ? trim((string) $opt) : '')
                ->filter(fn($opt) => $opt !== '')
                ->values()
                ->all();

            if ($type === 'select' && $options === []) {
                return $this->errorResponse('Validasi gagal', 'VALIDATION_ERROR', 422, [
                    "fields.{$index}.options" => ['Field select wajib memiliki minimal satu opsi.'],
                ]);
            }
        }

        $template = ServiceFormTemplate::query()->updateOrCreate(
            ['category' => $targetCategory],
            [
                'name' => $request->string('name')->toString(),
                'fields' => $request->input('fields'),
                'is_active' => (bool) $request->boolean('is_active', true),
            ]
        );

        Cache::forget('service_templates.all');
        Cache::forget('service_templates.' . $targetCategory);

        return $this->successResponse($template, 'Template layanan berhasil disimpan');
    }

    public function updateStatus(UpdateServiceStatusRequest $request, ServiceApplication $application): JsonResponse
    {
        $application->update([
            'status' => $request->string('status')->toString(),
            'admin_note' => $request->string('admin_note')->toString() ?: null,
        ]);

        $actorId = auth('sanctum')->id();
        $this->pushNotificationService->notifyUsers(
            [$application->user_id],
            'Status layanan diperbarui',
            "Pengajuan {$application->category} Anda sekarang berstatus {$application->status}.",
            'service_application',
            'service_application_status_updated',
            $actorId,
            [
                'application_id' => $application->id,
                'category' => $application->category,
                'status' => $application->status,
            ]
        );

        return $this->successResponse($application, 'Status pendaftaran layanan berhasil diperbarui');
    }

    public function updateApplication(UpdateServiceApplicationRequest $request, ServiceApplication $application): JsonResponse
    {
        $template = ServiceFormTemplate::query()
            ->where('category', $request->string('category')->toString())
            ->where('is_active', true)
            ->first();

        if (! $template) {
            return $this->errorResponse('Kategori layanan tidak tersedia', 'VALIDATION_ERROR', 422, [
                'category' => ['Kategori layanan tidak tersedia atau belum aktif.'],
            ]);
        }

        $formData = $request->input('form_data', []);
        $dynamicRules = [];

        foreach ($template->fields as $field) {
            $key = $field['key'] ?? null;
            $type = $field['type'] ?? 'string';
            $required = (bool) ($field['required'] ?? false);

            if (! is_string($key) || $key === '') {
                continue;
            }

            $rules = [$required ? 'required' : 'nullable'];

            if ($type === 'string') {
                $rules[] = 'string';
            }

            if ($type === 'date') {
                $rules[] = 'date';
            }

            if ($type === 'number') {
                $rules[] = 'numeric';
            }

            if ($type === 'boolean') {
                $rules[] = 'boolean';
            }

            if ($type === 'select') {
                $rules[] = 'string';
                $options = collect($field['options'] ?? [])
                    ->map(fn($opt) => is_scalar($opt) ? (string) $opt : null)
                    ->filter(fn($opt) => is_string($opt) && $opt !== '')
                    ->values()
                    ->all();

                if ($options !== []) {
                    $rules[] = Rule::in($options);
                }
            }

            $dynamicRules[$key] = $rules;
        }

        $validator = Validator::make($formData, $dynamicRules);

        if ($validator->fails()) {
            return $this->errorResponse('Validasi gagal', 'VALIDATION_ERROR', 422, $validator->errors()->toArray());
        }

        $application->update([
            'category' => $request->string('category')->toString(),
            'form_data' => $formData,
            'attachments' => $request->input('attachments', []),
        ]);

        return $this->successResponse($application->fresh('user'), 'Pengajuan layanan berhasil diperbarui');
    }

    public function destroyTemplate(string $category): JsonResponse
    {
        $template = ServiceFormTemplate::query()->where('category', $category)->first();

        if (! $template) {
            return $this->errorResponse('Template layanan tidak ditemukan', 'NOT_FOUND', 404);
        }

        $template->delete();

        Cache::forget('service_templates.all');
        Cache::forget('service_templates.' . $category);

        return $this->successResponse(null, 'Template layanan berhasil dihapus');
    }

    public function exportApplicationCertificate(ServiceApplication $application)
    {
        $actor = auth('sanctum')->user();

        if (! $actor) {
            return $this->errorResponse('Unauthorized', 'UNAUTHORIZED', 401);
        }

        $isOwner = (int) $actor->id === (int) $application->user_id;
        $isAdmin = (string) $actor->role === 'admin';

        if (! $isOwner && ! $isAdmin) {
            return $this->errorResponse('Forbidden', 'FORBIDDEN', 403);
        }

        $pdf = Pdf::loadView('pdf.service_application_certificate', [
            'application' => $application->load('user'),
        ]);

        return $pdf->download("service-application-{$application->id}-certificate.pdf");
    }
}
