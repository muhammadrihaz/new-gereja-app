# 14 - Known Issues

## 🔴 CRITICAL

### KI-01: Hardcoded Development Credentials

- **Problem**: Credentials testing (email, password) di-hardcode di `lib/src/core/environment.dart`
- **Penyebab**: Convenience saat development
- **Impact**: Jika included di production build, credentials bisa diekstrak dari APK/bundle
- **Saran Perbaikan**: Pindahkan ke environment variable atau pastikan hanya ada di debug build via conditional compilation

### KI-02: ServiceApplicationExportController PDF Placeholder

- **Problem**: Method `exportApplicationPdf` berisi placeholder, bukan implementasi nyata
  ```php
  // TODO: Implement PDF generation logic using Laravel DomPDF or similar
  return response()->download(storage_path('app/placeholder.pdf'), ...);
  ```
- **Penyebab**: Fitur belum selesai diimplementasi
- **Impact**: Endpoint akan error karena file `placeholder.pdf` tidak ada
- **Saran Perbaikan**: Implementasi PDF generation atau hapus endpoint dari route

### KI-03: ServiceApplicationExportController admin_notes Typo

- **Problem**: Property yang diakses di `generateCsv` → `$app->admin_notes` seharusnya `$app->admin_note` (tanpa 's')
- **Penyebab**: Typo — model menggunakan `admin_note` (singular)
- **Impact**: Kolom admin notes di CSV selalu kosong
- **Saran Perbaikan**: Ubah `$app->admin_notes` menjadi `$app->admin_note`

## 🟡 HIGH

### KI-04: Duplicate Schedule Configuration

- **Problem**: Schedule didefinisikan di **dua tempat**: `routes/console.php` dan `app/Console/Kernel.php`
- **Penyebab**: Laravel 11+ tidak lagi memuat `Kernel.php` scheduler otomatis, tapi file Kernel masih ada dengan schedule yang sama
- **Impact**: Scheduler di Kernel.php tidak dieksekusi (dead code). Bisa membingungkan developer.
- **Saran Perbaikan**: Hapus method `schedule()` di `Kernel.php`, pertahankan hanya di `routes/console.php`

### KI-05: CORS Wildcard di Production

- **Problem**: CORS `allowed_origins` = `['*']` tanpa domain restriction
- **Penyebab**: Konfigurasi development yang terbawa ke production
- **Impact**: Semua origin bisa mengakses API
- **Saran Perbaikan**: Set specific origins untuk production

### KI-06: Event Category FK Not Enforced

- **Problem**: Migrasi `add_fk_events_category` menambahkan foreign key, tapi model `Event` menyimpan `category` sebagai string, bukan ID
- **Penyebab**: Evolusi schema — awalnya category string, lalu ditambahkan tabel categories
- **Impact**: Potensi data inkonsisten antara `events.category` dan `event_categories.code`
- **Saran Perbaikan**: Validasi kategori di controller saat create/update event (sudah dilakukan di ServiceController, belum di EventController)

### KI-07: Missing Event Category Validation

- **Problem**: `EventController::store` dan `EventController::update` tidak memvalidasi apakah `category` yang diberikan ada di tabel `event_categories`
- **Penyebab**: Validasi hanya ada di `ServiceController` (untuk service categories)
- **Impact**: Event bisa dibuat dengan kategori yang tidak valid
- **Saran Perbaikan**: Tambahkan validasi `exists:event_categories,code` di `StoreEventRequest`

## 🟢 LOW

### KI-08: Documentation Model Unused

- **Problem**: Model `Documentation` ada tapi tabel sudah di-drop via migrasi `drop_documentations_table`
- **Penyebab**: Refactoring — digantikan oleh `EventDocumentation`
- **Impact**: Dead code, bisa membingungkan
- **Saran Perbaikan**: Hapus file `app/Models/Documentation.php`

### KI-09: No Password Reset Feature

- **Problem**: Tidak ada endpoint untuk forgot password / reset password
- **Penyebab**: Fitur belum diimplementasi
- **Impact**: User yang lupa password harus minta admin untuk reset manual
- **Saran Perbaikan**: Implementasi password reset via email

### KI-10: Event Attendees Fallback

- **Problem**: `NotificationTargetingService::applyEventAttendeesFallback` selalu fallback ke semua jemaat, bukan actual attendees
- **Penyebab**: Attendance module belum diimplementasi
- **Impact**: Broadcast ke "event_attendees" mengirim ke semua jemaat, bukan yang attend
- **Saran Perbaikan**: Implementasi attendance tracking module

### KI-11: Google Sign-In Not Implemented

- **Problem**: `GoogleSignInButton` widget dan placeholder credentials ada, tapi fitur tidak terimplementasi
- **Penyebab**: Planned feature yang belum dikembangkan
- **Impact**: Rendah — button mungkin ditampilkan tapi tidak berfungsi
- **Saran Perbaikan**: Implementasi atau sembunyikan button sampai siap

### KI-12: Duplicate resolveStoredAbsolutePath

- **Problem**: Method `resolveStoredAbsolutePath` diduplikasi di `EventController` dan `NewsController` dengan logic yang identik
- **Penyebab**: Copy-paste tanpa refactoring
- **Impact**: Maintenance burden — perubahan harus di dua tempat
- **Saran Perbaikan**: Extract ke shared trait atau service
