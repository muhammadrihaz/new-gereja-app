# 20 - AI Rules

> **File ini WAJIB dibaca oleh AI Agent sebelum melakukan modifikasi apapun.**

## Aturan Umum

1. **Jangan mengubah coding style.** Ikuti konvensi yang sudah ada (lihat `docs/10-coding-standard.md`)
2. **Jangan mengubah struktur folder.** Controllers di `app/Http/Controllers/`, Models di `app/Models/`, dll
3. **Jangan mengganti dependency tanpa alasan kuat.** Diskusikan dulu perubahan dependency
4. **Jangan membuat duplicate logic.** Periksa apakah fungsi serupa sudah ada
5. **Jangan mengarang informasi.** Jika tidak yakin, tanyakan atau baca source code

## Aturan Controller

1. **Selalu gunakan `use ApiResponse` trait** di setiap controller baru
2. **Selalu return `JsonResponse`** dari method controller
3. **Selalu gunakan `$this->successResponse()` atau `$this->errorResponse()`** untuk response
4. **Selalu gunakan `auth('sanctum')->user()` atau `auth('sanctum')->id()`** untuk mendapatkan user
5. **Selalu gunakan `Model::query()->` bukan `Model::`** untuk memulai query Eloquent
6. **Response message selalu dalam Bahasa Indonesia**
7. **Jangan langsung return Eloquent model** tanpa format — gunakan `$this->successResponse()` wrapper

## Aturan Validasi

1. **Gunakan Form Request** untuk validasi input (buat di `app/Http/Requests/{Domain}/`)
2. **Ikuti pola penamaan**: `StoreXxxRequest`, `UpdateXxxRequest`, `UpsertXxxRequest`
3. **Jangan inline validation** (`$request->validate()`) kecuali untuk operasi sangat sederhana
4. **Error code konsisten**: `VALIDATION_ERROR`, `NOT_FOUND`, `FORBIDDEN`, `UNAUTHORIZED`, dll

## Aturan Service

1. **Gunakan Service** jika logic melibatkan multiple model atau external service
2. Service di-inject via constructor: `public function __construct(private readonly ServiceClass $service) {}`
3. **Jangan query database langsung di Controller** jika sudah ada Service yang menangani area tersebut
4. Notification selalu melalui `PushNotificationService`

## Aturan Database

1. **Selalu buat migration** untuk perubahan schema — jangan edit migration yang sudah dijalankan
2. Penamaan migration: `YYYY_MM_DD_NNNNNN_action_description.php`
3. Penamaan tabel: `snake_case`, plural (e.g., `service_applications`)
4. Penamaan kolom: `snake_case` (e.g., `created_by`, `nomor_kk`)
5. Gunakan soft delete hanya jika business logic membutuhkan (saat ini tidak digunakan)
6. **Selalu definisikan `$fillable`** di model — jangan gunakan `$guarded`

## Aturan Route

1. Route ditambahkan di `api/routes/api.php`
2. **Prefix**: semua route di bawah `/api/v1/`
3. **Public route**: di luar group `auth:sanctum`
4. **Authenticated route**: di dalam `middleware(['auth:sanctum', 'throttle:api-default'])`
5. **Admin-only route**: di dalam nested `middleware('can:admin')`
6. **Write operations**: tambahkan `->middleware('throttle:api-write')`
7. **Broadcast**: gunakan `->middleware('throttle:broadcast')`

## Aturan Notifikasi

1. Kirim notifikasi melalui `PushNotificationService->notifyUsers()` atau `notifyDevices()`
2. Jangan langsung call FCM API
3. Selalu log notifikasi ke `notification_dispatch_logs`
4. Invalidate cache setelah write operation yang mempengaruhi data cached

## Aturan Cache

1. Gunakan `Cache::remember()` untuk read operation yang sering
2. Gunakan `Cache::forget()` untuk invalidate setelah write
3. Cache key convention: `{entity}.{filter}` (e.g., `event_categories.active`, `service_templates.all`)
4. Default TTL: 600 detik (10 menit)

## Aturan File Upload

1. File disimpan di disk `public` (`Storage::disk('public')`)
2. Path format: `{entity-type}/{entity-id}/filename`
3. Cleanup: hapus file dari storage saat entity dihapus

## Aturan Flutter

1. **Semua API call** melalui `ApiClient` (`lib/src/core/api_client.dart`)
2. **Auth state** melalui `SessionController` (`lib/src/core/session_controller.dart`)
3. Page naming: `{role}_{feature}_page.dart` (e.g., `admin_jemaat_page.dart`, `jemaat_berita_page.dart`)
4. Widget reusable di `lib/src/widgets/`
5. Gunakan `ChangeNotifier` + `Provider` pattern (sudah ada di project)

## Larangan

- ❌ Jangan hapus atau disable middleware `TraceIdMiddleware` dan `ApiActivityLoggingMiddleware`
- ❌ Jangan ubah format response `ApiResponse` trait
- ❌ Jangan hardcode credentials
- ❌ Jangan return stack trace di production (`APP_DEBUG=false`)
- ❌ Jangan query tanpa pagination untuk list endpoints
- ❌ Jangan bypass authentication/authorization
- ❌ Jangan commit file `.env` yang berisi credentials real
- ❌ Jangan edit migration yang sudah di-run — buat migration baru
- ❌ Jangan tambahkan package tanpa memastikan kompatibilitas
- ❌ Jangan ubah bahasa response message (harus Bahasa Indonesia)

## Checklist Sebelum Perubahan

- [ ] Sudah membaca `docs/13-ai-context.md`
- [ ] Sudah memahami business rules di `docs/07-business-rules.md`
- [ ] Mengikuti coding standard di `docs/10-coding-standard.md`
- [ ] Controller menggunakan `ApiResponse` trait
- [ ] Validasi menggunakan Form Request
- [ ] Route memiliki middleware yang sesuai
- [ ] Migration dibuat untuk perubahan database
- [ ] Cache di-invalidate jika relevan
- [ ] Response message dalam Bahasa Indonesia
- [ ] Error code mengikuti konvensi yang ada
- [ ] Test sudah dijalankan (`php artisan test`)
- [ ] Tidak ada hardcoded credentials
- [ ] Tidak ada duplicate logic
