# 13 - AI Context

> **File ini ditujukan untuk AI Agent.** Berisi konteks lengkap agar AI Agent dapat memahami dan memodifikasi project tanpa membaca seluruh source code.

## Project Summary

Aplikasi manajemen gereja digital dengan arsitektur **Flutter (frontend mobile/web) + Laravel 13 REST API (backend)**. Mengelola data jemaat, event, berita, layanan gereja, notifikasi push, dan registrasi Kartu Keluarga.

## Tech Stack

| Layer             | Teknologi                       |
| ----------------- | ------------------------------- |
| Frontend          | Flutter (Dart ^3.10.8)          |
| Backend           | Laravel 13 (PHP ^8.3)           |
| Database          | MariaDB 11.4 (MySQL compatible) |
| Cache             | Redis 7 / Database              |
| Queue             | Database driver (bisa Redis)    |
| Auth              | Laravel Sanctum (token-based)   |
| Push Notification | Firebase Cloud Messaging v1     |
| Email             | Resend / SMTP                   |
| PDF               | DomPDF                          |
| Container         | Docker Compose                  |
| Server            | Nginx + PHP-FPM 8.4             |

## Folder yang Penting

| Path                                   | Fungsi                                   |
| -------------------------------------- | ---------------------------------------- |
| `api/app/Http/Controllers/`            | Semua API controller                     |
| `api/app/Models/`                      | Semua Eloquent model                     |
| `api/app/Services/`                    | Business logic services                  |
| `api/app/Support/ApiResponse.php`      | Trait untuk standarisasi response        |
| `api/app/Http/Requests/`               | Form request validation (per domain)     |
| `api/app/Http/Middleware/`             | Custom middleware                        |
| `api/app/Console/Commands/`            | Artisan commands                         |
| `api/app/Jobs/`                        | Queue jobs                               |
| `api/routes/api.php`                   | Semua API routes                         |
| `api/routes/console.php`               | Scheduled tasks                          |
| `api/database/migrations/`             | Database migrations                      |
| `api/config/services.php`              | Third-party service config (FCM, Resend) |
| `lib/src/core/api_client.dart`         | Flutter HTTP client                      |
| `lib/src/core/session_controller.dart` | Flutter auth state                       |
| `lib/src/pages/`                       | Semua Flutter pages                      |

## Konvensi Coding

- Controller selalu pakai `use ApiResponse` trait
- Response selalu via `$this->successResponse()` / `$this->errorResponse()`
- Auth: `auth('sanctum')->user()` / `auth('sanctum')->id()`
- Validasi: Form Request classes di `app/Http/Requests/{Domain}/`
- Model: `Model::query()->create()`, `Model::query()->where()`
- Pesan response selalu **Bahasa Indonesia**
- Nama tabel: snake_case plural
- Nama kolom: snake_case

## Cara Membuat Controller Baru

1. Buat file di `api/app/Http/Controllers/NamaController.php`
2. Extend `Controller`
3. `use ApiResponse;`
4. Buat Form Request di `api/app/Http/Requests/{Domain}/`
5. Tambahkan route di `api/routes/api.php`
6. Jika admin-only: letakkan di dalam group `middleware('can:admin')`

```php
<?php

namespace App\Http\Controllers;

use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class NamaController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        return $this->successResponse([], 'Berhasil');
    }
}
```

## Cara Membuat API Baru

1. Buat Controller + Form Request (jika perlu)
2. Tambahkan di `api/routes/api.php`:
   - **Public**: Di luar group `auth:sanctum`
   - **Authenticated**: Di dalam `middleware(['auth:sanctum', 'throttle:api-default'])`
   - **Admin-only**: Di dalam nested `middleware('can:admin')`
3. Tambahkan `throttle:api-write` untuk operasi write

## Cara Membuat Migration Baru

```bash
cd api
php artisan make:migration create_nama_table
```

Konvensi penamaan: `YYYY_MM_DD_NNNNNN_action_nama_table.php`

## Cara Membuat Model Baru

```bash
cd api
php artisan make:model NamaModel
```

- Tambahkan `use HasFactory;`
- Definisikan `$fillable`, `casts()`, relationships
- Letakkan di `api/app/Models/`

## Cara Membuat Feature Baru

1. ✅ Migration: `php artisan make:migration`
2. ✅ Model: `php artisan make:model`
3. ✅ Form Request: buat manual di `app/Http/Requests/{Domain}/`
4. ✅ Controller: buat manual dengan `use ApiResponse`
5. ✅ Route: tambahkan di `api/routes/api.php`
6. ✅ Service (opsional): jika logic kompleks, buat di `app/Services/`
7. ✅ Flutter Page: buat di `lib/src/pages/`
8. ✅ API Client method: tambahkan di `lib/src/core/api_client.dart`

## Cara Membuat View Baru (Flutter)

1. Buat file di `lib/src/pages/nama_page.dart`
2. Buat `StatefulWidget` atau `StatelessWidget`
3. Gunakan `ApiClient` dari `SessionController` untuk API calls
4. Tambahkan routing di `lib/main.dart`

## Cara Testing

```bash
cd api
php artisan test           # Run semua test
php artisan test --filter=TestName  # Run test spesifik
composer test              # Via composer script
```

## Hal yang TIDAK BOLEH Dilakukan AI

1. ❌ Jangan ubah format response API (harus tetap pakai `ApiResponse` trait)
2. ❌ Jangan buat controller tanpa `use ApiResponse`
3. ❌ Jangan bypass validation — gunakan Form Request
4. ❌ Jangan query database langsung di controller jika sudah ada Service
5. ❌ Jangan ubah struktur folder tanpa alasan
6. ❌ Jangan ubah naming convention
7. ❌ Jangan tambah dependency tanpa alasan kuat
8. ❌ Jangan hardcode credentials
9. ❌ Jangan ubah migration yang sudah dijalankan (buat migration baru)
10. ❌ Jangan mengubah atau menghapus middleware TraceId dan ApiActivityLogging

## Hal yang HARUS Dilakukan AI

1. ✅ Selalu gunakan `ApiResponse` trait di controller
2. ✅ Selalu buat Form Request untuk validasi
3. ✅ Selalu gunakan Bahasa Indonesia untuk response message
4. ✅ Selalu tambahkan throttle middleware pada route baru
5. ✅ Selalu gunakan `Model::query()->` bukan `Model::` untuk query
6. ✅ Selalu handle error codes yang konsisten (VALIDATION_ERROR, NOT_FOUND, FORBIDDEN, dll)
7. ✅ Selalu tambahkan trace_id di response
8. ✅ Selalu invalidate cache yang relevan setelah write operation
9. ✅ Selalu buat migration untuk perubahan database

## Pattern yang Digunakan

| Pattern           | Detail                                                          |
| ----------------- | --------------------------------------------------------------- |
| MVC + Service     | Controllers handle HTTP, Services handle complex business logic |
| Repository        | Tidak digunakan — query langsung via Eloquent                   |
| Trait             | `ApiResponse` untuk standarisasi response                       |
| Form Request      | Validasi via dedicated Request classes                          |
| API Resource      | `EventResource`, `NewsResource` untuk transformasi response     |
| Upsert            | `updateOrCreate` digunakan untuk FCM token dan templates        |
| Soft Delete       | Tidak digunakan                                                 |
| Observer/Listener | Tidak digunakan                                                 |
| Cache Aside       | Manual `Cache::remember()` + `Cache::forget()`                  |

## Daftar Reusable Component (Flutter)

| Widget               | File                                | Fungsi                  |
| -------------------- | ----------------------------------- | ----------------------- |
| `CachedImage`        | `widgets/cached_image.dart`         | Cached network image    |
| `ChurchLogo`         | `widgets/church_logo.dart`          | Church logo display     |
| `EmptyState`         | `widgets/empty_state.dart`          | Empty state placeholder |
| `ErrorState`         | `widgets/error_state.dart`          | Error state display     |
| `GoogleSignInButton` | `widgets/google_signin_button.dart` | Google sign-in button   |
| `PwaInstallFab`      | `widgets/pwa_install_fab.dart`      | PWA install FAB         |
| `SkeletonList`       | `widgets/skeleton_list.dart`        | Loading skeleton        |

## Daftar Service

| Service                        | File                                        | Fungsi                          |
| ------------------------------ | ------------------------------------------- | ------------------------------- |
| `PushNotificationService`      | `Services/PushNotificationService.php`      | Kirim push + email notification |
| `FcmAccessTokenProvider`       | `Services/FcmAccessTokenProvider.php`       | OAuth2 token untuk FCM v1       |
| `FcmAuthService`               | `Services/FcmAuthService.php`               | FCM auth wrapper                |
| `NotificationTargetingService` | `Services/NotificationTargetingService.php` | Resolve target devices          |

## Daftar Middleware

| Middleware                     | Fungsi                             |
| ------------------------------ | ---------------------------------- |
| `TraceIdMiddleware`            | Generate/forward X-Trace-Id header |
| `ApiActivityLoggingMiddleware` | Log API activity ke database       |

## Daftar Command Artisan

| Command           | Class                         | Fungsi                       |
| ----------------- | ----------------------------- | ---------------------------- |
| Archive Events    | `ArchiveExpiredEventsCommand` | Auto-archive expired events  |
| Event Reminder    | `SendEventReminderCommand`    | Push reminder H-2            |
| Last Call         | `SendEventLastCallCommand`    | Push reminder H-1            |
| Service Follow-up | `SendServiceFollowUpCommand`  | Follow-up stale applications |
| KK Reminder       | `SendKkReminderCommand`       | KK registration reminder     |
| Admin Digest      | `SendAdminDigestCommand`      | Weekly digest                |
| FCM Diagnose      | `FcmDiagnoseCommand`          | Diagnose FCM config          |
| FCM Test Send     | `FcmTestSendCommand`          | Test FCM push                |
| Test Email        | `SendTestEmailCommand`        | Test email sending           |

## Daftar ENV Penting

| Variable                                             | Kritis                      |
| ---------------------------------------------------- | --------------------------- |
| `APP_KEY`                                            | Wajib — encryption key      |
| `DB_*`                                               | Wajib — database connection |
| `FCM_ENABLED`                                        | Aktifkan push notification  |
| `FCM_CREDENTIALS_JSON` atau `FCM_CREDENTIALS_BASE64` | FCM v1 auth                 |
| `EMAIL_NOTIFICATIONS_ENABLED`                        | Aktifkan email fallback     |
| `QUEUE_CONNECTION`                                   | Queue driver                |

## Checklist Sebelum AI Melakukan Perubahan

- [ ] Baca `docs/07-business-rules.md` untuk memahami business rules
- [ ] Baca `docs/06-api.md` untuk memahami API yang ada
- [ ] Baca `docs/10-coding-standard.md` untuk mengikuti konvensi
- [ ] Pastikan menggunakan `ApiResponse` trait
- [ ] Pastikan membuat Form Request untuk validasi
- [ ] Pastikan response message dalam Bahasa Indonesia
- [ ] Pastikan route memiliki middleware yang benar
- [ ] Pastikan membuat migration untuk perubahan database
- [ ] Pastikan invalidate cache yang relevan
- [ ] Jalankan `php artisan test` sebelum commit
