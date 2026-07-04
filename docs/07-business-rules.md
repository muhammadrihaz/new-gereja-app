# 07 - Business Rules

## 1. Registrasi & Autentikasi

### BR-AUTH-01: Verifikasi KK saat Registrasi

- User **wajib** menyertakan `nomor_kk` yang sudah terdaftar di tabel `kk_registrations`
- Nama user harus cocok (case-insensitive, whitespace-normalized) dengan:
  - `nama_kepala_keluarga` di `kk_registrations`, **ATAU**
  - `name` salah satu `users` yang memiliki `nomor_kk` yang sama
- Jika tidak cocok: error `KK_OR_NAME_NOT_REGISTERED` (422)
- Normalisasi nama: lowercase, collapse whitespace

### BR-AUTH-02: Role Default

- Setiap user yang mendaftar via registrasi mendapat role `jemaat`
- Role `admin` hanya bisa diberikan secara manual (tidak ada endpoint untuk change role)

### BR-AUTH-03: Login Identifier

- User bisa login menggunakan `username` atau `email`
- Deteksi otomatis: jika mengandung `@` → email, jika tidak → username

### BR-AUTH-04: FCM Token saat Auth

- Saat register/login, FCM token di-register/update via `updateOrCreate`
- Token yang sama di-claim oleh user yang login terakhir

### BR-AUTH-05: Logout

- Logout menghapus **semua** Sanctum tokens user (bukan hanya current)

## 2. Event

### BR-EVT-01: Auto-Archive

- Event expired otomatis di-archive oleh `ArchiveExpiredEventsCommand` setiap 15 menit
- Event dianggap expired jika `end_at` (atau fallback `start_at` / `date`) sudah lewat

### BR-EVT-02: Visibilitas Jemaat

- Jemaat **hanya** bisa melihat event dengan `is_archived = false`
- Tambahan: event yang `end_at` sudah > 24 jam lalu juga disembunyikan meski belum di-archive
- Admin bisa melihat semua event termasuk yang archived

### BR-EVT-03: Revive dari Archive

- Jika admin update `end_at` event ke masa depan, event otomatis di-revive (`is_archived = false`, `archived_at = null`)

### BR-EVT-04: Reminder

- Push notification dikirim H-2 (`SendEventReminderCommand`, setiap 10 menit)
- Push notification "last call" dikirim H-1 (`SendEventLastCallCommand`, setiap 10 menit)

### BR-EVT-05: Upload Dokumentasi

- Total upload per request: max 200MB
- File disimpan di disk `public`

### BR-EVT-06: Download Dokumentasi

- Semua file dokumentasi event di-zip dan dikirim sebagai respons download
- File temp dihapus setelah dikirim

## 3. Berita

### BR-NEWS-01: Published Only

- Jemaat secara default hanya melihat berita yang `published_at <= now()`
- Admin bisa filter `published_only = false`

### BR-NEWS-02: Penghapusan Berita

- Saat berita dihapus, semua file lampiran di storage juga dihapus (cleanup orphan files)

## 4. Layanan Gereja

### BR-SVC-01: Wajib KK

- User **wajib** memiliki `nomor_kk` di profil sebelum bisa mengajukan layanan
- Jika belum ada: error `VALIDATION_ERROR` (422)

### BR-SVC-02: Validasi Form Dinamis

- Form data divalidasi secara dinamis berdasarkan `ServiceFormTemplate.fields[]`
- Tipe validasi: `string`, `date`, `number`, `boolean`, `select`
- Field `select` memvalidasi value terhadap `options[]`

### BR-SVC-03: Status Workflow

```
pending → approved
pending → rejected
```

- Status awal selalu `pending`
- Hanya admin yang bisa mengubah status

### BR-SVC-04: Notifikasi Otomatis

- Saat pengajuan baru: notifikasi ke **semua admin**
- Saat status berubah: notifikasi ke **user pengaju**

### BR-SVC-05: Admin Proxy Submit

- Admin bisa mengajukan layanan atas nama jemaat lain via `target_user_id`

### BR-SVC-06: Snapshot KK

- Saat pengajuan, `nomor_kk` user di-snapshot ke `nomor_kk_snapshot` untuk audit trail

### BR-SVC-07: Template Upsert

- Template form menggunakan `updateOrCreate` berdasarkan `category`
- Category body dan path harus sama jika keduanya disediakan
- Category harus ada di `service_categories` dan `is_active = true`

### BR-SVC-08: Cache Invalidation

- Setiap upsert/delete template → invalidate cache `service_templates.*`
- Setiap upsert/delete category → invalidate cache `*_categories.active`

## 5. Kartu Keluarga

### BR-KK-01: Uniqueness

- Nomor KK harus unik, minimal 16 karakter, max 32 karakter

### BR-KK-02: Deletion Guard

- KK **tidak dapat dihapus** jika masih ada anggota keluarga (users) yang terdaftar dengan nomor KK tersebut
- Error: `KK_HAS_MEMBERS` (422)

### BR-KK-03: Family Relation

- Anggota keluarga di-resolve via query `users` WHERE `nomor_kk` = KK's `nomor_kk`

## 6. Jemaat Management

### BR-JEM-01: Delete Guard

- Jemaat **tidak dapat dihapus** jika memiliki service application dengan status `pending`
- Error: `ACTIVE_APPLICATIONS_EXIST` (422)

### BR-JEM-02: Role Guard

- Hanya user dengan role `jemaat` yang dapat di-manage via JemaatManagementController
- Jika user bukan role jemaat: error `INVALID_ROLE` (422)

### BR-JEM-03: KK Validation

- Saat create jemaat, `nomor_kk` harus exist di `kk_registrations`

## 7. Notifikasi

### BR-NOT-01: FCM Token Lifecycle

- Token yang unregistered (NOT_FOUND / UNREGISTERED dari FCM) otomatis dihapus dari `user_devices`
- Token refresh: old token dihapus, new token di-claim

### BR-NOT-02: Deduplication

- Push notification di-deduplikasi per FCM token (satu token = satu kiriman per event)

### BR-NOT-03: Email Fallback

- Jika `EMAIL_NOTIFICATIONS_ENABLED = true`, email juga dikirim ke user yang memiliki email valid
- Email menggunakan `Mail::raw()`

### BR-NOT-04: FCM Queue Fallback

- Jika FCM tidak enabled/configured, notifikasi tetap di-log ke `notification_dispatch_logs` dengan status `queued`

### BR-NOT-05: Inbox

- Inbox menampilkan semua notifikasi kecuali yang provider-nya `email`
- Sorted by `id DESC` (newest first)

### BR-NOT-06: Broadcast Target Types

- `all` — semua device
- `role` — berdasarkan role (filter: `{role: "jemaat"}`)
- `users` — berdasarkan user IDs (filter: `{user_ids: [1,2,3]}`)
- `event_attendees` — fallback ke role `jemaat` (attendance module belum tersedia)
- `service_applicants` — berdasarkan `service_category` dan/atau `service_status`

## 8. Profil Gereja

### BR-CHR-01: Singleton

- Profil gereja adalah singleton (hanya satu record)
- Jika belum ada, otomatis dibuat saat `show()` dengan nama dari `config('app.name')`
- Cache 10 menit, invalidated saat update

## 9. API Activity Logging

### BR-LOG-01: Non-blocking

- API activity logging **tidak boleh** menggagalkan response (wrapped in try-catch)
- Sensitive fields (password, token) otomatis di-redact: `[redacted]`
- Response body hanya menyimpan: status, error_code, message, trace_id
- String payload > 500 char di-truncate
