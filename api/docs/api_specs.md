# API Documentation - Sistem Informasi GPI Yehuda (v1.1)

**Update:** Mendukung Multi-Device Push Notification (FCM)  
**Base URL:** `https://api.gpi-yehuda.org/api/v1`  
**Auth:** Laravel Sanctum (Bearer Token)  
**Content-Type:** `application/json`

---

## Prinsip Kontrak API (Backend, Frontend, QA)

Bagian ini memastikan spesifikasi bisa dipakai lintas tim (backend engineer, frontend engineer, dan QA) tanpa asumsi tersembunyi.

### A. Konvensi Request

- Semua endpoint protected wajib kirim header `Authorization: Bearer <token>`.
- Untuk body JSON, wajib kirim `Content-Type: application/json`.
- Untuk upload dokumentasi event, gunakan `multipart/form-data`.
- Field tanggal/jam wajib menggunakan format ISO 8601.
- Timezone API menggunakan offset `+08:00` (WITA) untuk data lokal.

Contoh format waktu:

```text
2026-04-12T09:00:00+08:00
```

Standar query untuk endpoint list:

- `page`: nomor halaman (default `1`).
- `per_page`: jumlah data per halaman (default `10`, max `100`).
- `sort_by`: field sorting yang diizinkan.
- `sort_order`: `asc` atau `desc`.

Standar payload lokasi dari maps:

- API menerima object `location` untuk endpoint yang memerlukan data lokasi.
- Frontend dapat mengirim data hasil select dari Google Maps, Apple Maps, atau provider maps lain.
- Untuk kompatibilitas client lama, `location` string masih diterima sementara (deprecated).

Contoh payload location object:

```json
{
    "location": {
        "name": "Gedung Utama GPI Yehuda",
        "address": "Jl. Sunset Road No. 767, Denpasar, Bali",
        "latitude": -8.670458,
        "longitude": 115.212629,
        "place_id": "ChIJ-example-place-id",
        "maps_url": "https://maps.google.com/?q=-8.670458,115.212629"
    }
}
```

Validasi location object:

- `location.address`: required, string, max 255.
- `location.latitude`: required, numeric, range -90 sampai 90.
- `location.longitude`: required, numeric, range -180 sampai 180.
- `location.name`: nullable, string, max 160.
- `location.place_id`: nullable, string, max 191.
- `location.maps_url`: nullable, url, max 500.

### B. Konvensi Response Sukses

Disarankan format respons konsisten berikut agar frontend mudah parsing:

```json
{
    "status": "success",
    "message": "Operasi berhasil",
    "data": {}
}
```

Catatan:

- Untuk endpoint download file (`/events/{id}/documentation/download`), response berupa binary stream (`application/zip`), bukan JSON.

Skema response untuk endpoint list (pagination):

```json
{
    "status": "success",
    "message": "Operasi berhasil",
    "data": [],
    "meta": {
        "current_page": 1,
        "per_page": 10,
        "total": 125,
        "last_page": 13
    },
    "links": {
        "first": "https://api.gpi-yehuda.org/api/v1/events?page=1",
        "last": "https://api.gpi-yehuda.org/api/v1/events?page=13",
        "prev": null,
        "next": "https://api.gpi-yehuda.org/api/v1/events?page=2"
    }
}
```

### C. Konvensi Response Error

Disarankan format respons error konsisten berikut:

```json
{
    "status": "error",
    "error_code": "VALIDATION_ERROR",
    "message": "Validasi gagal",
    "trace_id": "req-7f3ab91c",
    "errors": {
        "fcm_token": ["The fcm token field is required."]
    }
}
```

Catatan QA:

- `errors` hanya muncul untuk kasus validasi (`422`).
- Untuk `401`, `403`, `404`, cukup `status` dan `message` jika tidak ada detail field-level.
- `error_code` wajib konsisten antar endpoint agar frontend dan QA mudah membuat mapping.

### D. Aturan Akses Role

- **Admin only:** `POST /events`, `POST /events/{id}/documentation`, `POST /notifications/broadcast`, `PATCH /services/applications/{id}/status`, `POST /services/forms`, `PUT /services/forms/{category}`, `DELETE /services/forms/{category}`, `PUT /church/profile`.
- **Jemaat + Admin:** endpoint profil user sendiri, daftar event, apply layanan, download dokumentasi event (`GET /events/{id}/documentation/download`), baca template layanan (`GET /services/forms`, `GET /services/forms/{category}`), unduh sertifikat pengajuan layanan miliknya (`GET /services/applications/{id}/certificate/pdf`), dan baca profil gereja (`GET /church/profile`).

### D.1 Daftar Endpoint Inti Autentikasi & Device

Autentikasi:

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `POST /auth/logout`

Manajemen device:

- `POST /devices/register`
- `DELETE /devices/revoke`
- `DELETE /devices/revoke-all`
- `GET /devices`

### E. Checklist Integrasi Frontend

1. Simpan token Sanctum setelah login, dan kirim di setiap request protected.
2. Panggil `POST /devices/register` setelah login sukses dan saat refresh token FCM.
3. Saat logout, panggil `DELETE /devices/revoke` sebelum token lokal dihapus.
4. Untuk download ZIP, frontend harus handle binary response (blob/file stream), bukan JSON parser.
5. Tampilkan pesan error berdasarkan `message` dari API, dan tampilkan error field dari `errors` saat `422`.
6. Gunakan `trace_id` pada setiap response untuk korelasi log jika ada issue di produksi.

### F. Checklist QA (Minimum)

1. Uji semua endpoint dengan token valid dan tanpa token.
2. Uji role jemaat mencoba endpoint admin (`403 Forbidden`).
3. Uji validasi field wajib (`422 Validation Error`).
4. Uji download dokumentasi saat file ada (`200`) dan saat tidak ada (`404`).
5. Uji multi-device: satu user dengan lebih dari satu `fcm_token` menerima notifikasi.

## Mapping Checklist Kepatuhan

1. Pagination: diterapkan melalui standar `page`, `per_page`, `sort_by`, `sort_order` + skema `meta`/`links`.
2. Error code standar: menggunakan `error_code` + tabel status code standar.
3. Response schema jelas: response sukses/error baku, termasuk skema list (pagination).
4. Upload constraint: didefinisikan pada endpoint upload dokumentasi.
5. Notification targeting: didefinisikan pada endpoint broadcast.
6. Device management lebih aman: validasi kepemilikan token, revoke all devices, pembaruan `last_active`.
7. Resource & Request: standar Laravel API Resource + Form Request.
8. Clean code implementation: dipandu oleh section khusus clean architecture & coding standard.
9. Activity log endpoint-level: semua request API terekam di `api_activity_logs` dengan `trace_id`, status code, durasi, IP, user id.
10. Security hardening: endpoint write memakai limiter tambahan (`throttle:api-write`) dan endpoint sensitif memakai limiter khusus (`auth-login`, `auth-register`, `broadcast`).

## 0. Keamanan, Traceability, dan FCM

1. Seluruh endpoint API otomatis menghasilkan dan mengembalikan `X-Trace-Id` serta `trace_id` di response body untuk kebutuhan troubleshooting.
2. Semua aktivitas endpoint disimpan di tabel `api_activity_logs` agar investigasi incident lebih cepat.
3. Payload sensitif seperti password/token di-redact dalam activity log.
4. Integrasi push notification menggunakan FCM untuk seluruh modul (auth/device, event, service, dan broadcast), dikelola terpusat di service notifikasi.
5. Konfigurasi environment FCM:
    - `FCM_ENABLED=true|false`
    - `FCM_SERVER_KEY=...`
    - `FCM_PROJECT_ID=...`
    - `FCM_ENDPOINT=https://fcm.googleapis.com/fcm/send`

### 0.1 Dukungan Channel Notifikasi

1. Push notification (FCM) sudah disiapkan sebagai channel utama lintas modul.
2. Email notification juga tersedia sebagai channel tambahan (opsional) dengan toggle env:
    - `EMAIL_NOTIFICATIONS_ENABLED=true|false`
3. Jika email diaktifkan, pengiriman mengikuti konfigurasi SMTP Laravel (`MAIL_*`).

### 0.2 Strategy Storage per Environment

1. Localhost / Docker development:
    - Gunakan `FILESYSTEM_DISK=local`.
    - Jalankan `php artisan storage:link` agar file public dapat diakses via `/storage/...`.
2. Staging / Production:
    - Gunakan object storage dengan `FILESYSTEM_DISK=s3` (S3 compatible bucket).
    - Set kredensial object storage: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, `AWS_BUCKET`, `AWS_ENDPOINT` (jika non-AWS), dan `AWS_USE_PATH_STYLE_ENDPOINT` sesuai provider.
    - Jangan mengandalkan local disk untuk deployment produksi.

### 0.3 Langkah Menghubungkan FCM ke Laravel API

1. Ambil server key/project credentials dari Firebase Console.
2. Set env pada API:
    - `FCM_ENABLED=true`
    - `FCM_SERVER_KEY=<server-key-fcm>`
    - `FCM_PROJECT_ID=<firebase-project-id>`
    - `FCM_ENDPOINT=https://fcm.googleapis.com/fcm/send`
3. Pastikan Flutter mengirim `fcm_token` saat register/login atau refresh token device (`POST /devices/register`).
4. Lakukan uji kirim melalui endpoint admin `POST /notifications/broadcast`.
5. Validasi hasil kirim pada tabel `notification_dispatch_logs` (`provider=fcm`, `status`, `trace_id`).

### 0.4 Tanda API Siap Dikonsumsi Flutter

1. Endpoint `GET /health` mengembalikan marker `flutter_ready=true`.
2. Endpoint yang sama juga memuat daftar `features` aktif (auth, push notification, email notification, trace id, rate limiter).
3. Semua response API membawa `trace_id` untuk debugging terintegrasi antara Flutter app log dan backend log.

## 1. Autentikasi & Multi-Device Management

Untuk mendukung banyak perangkat, setiap kali user login atau membuka aplikasi, Flutter harus mengirimkan token ke server.

### 1.1 Login & Registrasi

Tetap menggunakan spesifikasi sebelumnya, namun pastikan `fcm_token` selalu dikirimkan.

#### 1.1.1 Registrasi Jemaat

- **Method:** `POST`
- **Endpoint:** `/auth/register`
- **Catatan wajib:** `nomor_kk` wajib diisi saat registrasi jemaat.
- **Request Body:**

```json
{
    "username": "novalia_yordan",
    "email": "nova@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "nomor_kk": "5171012345678901",
    "jenis_kelamin": "P",
    "usia": 22,
    "alamat": "Jl. Sunset Road No. 767, Bali",
    "fcm_token": "string_token_firebase"
}
```

Constraint minimum registrasi jemaat:

- `username`: required, unique.
- `email`: required, unique.
- `password`: required, min 8, confirmed.
- `nomor_kk`: required, string, min 16, max 32.
- `fcm_token`: required, min 20.

### 1.1.3 Data Keluarga (Admin)

Untuk kebutuhan pengelompokan anggota keluarga berdasarkan Kartu Keluarga.

- **Method:** `GET`
- **Endpoint:** `/users/families`
- **Auth:** `Bearer Token` (Admin only)
- **Query:**
    - `search` (optional): cari berdasarkan nomor KK / nama / username / email anggota
    - `page` (optional): default 1
    - `per_page` (optional): default 10, max 100

**Response Success (200):**

```json
{
    "status": "success",
    "message": "Daftar keluarga jemaat berhasil diambil",
    "data": [
        {
            "nomor_kk": "5171012345678901",
            "total_members": 3,
            "members": [
                {
                    "id": 10,
                    "name": "Ayu",
                    "username": "ayu01",
                    "email": "ayu@example.com",
                    "nomor_kk": "5171012345678901"
                }
            ]
        }
    ],
    "meta": {
        "current_page": 1,
        "per_page": 10,
        "total": 1,
        "last_page": 1
    }
}
```

#### 1.1.2 Login

- **Method:** `POST`
- **Endpoint:** `/auth/login`
- **Request Body:**

```json
{
    "email": "nova@example.com",
    "password": "password123",
    "fcm_token": "string_token_device_terbaru"
}
```

- **Response Success (200):**

```json
{
    "status": "success",
    "token": "1|abc123token...",
    "role": "jemaat",
    "user": {
        "id": 1,
        "username": "novalia_yordan",
        "email": "nova@example.com"
    }
}
```

### 1.2 Simpan/Update Device Token

Gunakan endpoint ini setiap kali aplikasi Flutter diinisialisasi atau setelah login sukses.

- **Method:** `POST`
- **Endpoint:** `/devices/register`
- **Request Body:**

```json
{
    "fcm_token": "token_unik_dari_firebase",
    "device_name": "iPhone 15 Pro / Chrome Browser",
    "device_type": "ios"
}
```

Keterangan nilai `device_type`: `android`, `ios`, atau `web`.

Constraint request:

- `fcm_token`: required, string, unique by token, min 20 chars.
- `device_name`: nullable, string, max 120.
- `device_type`: required, enum `android|ios|web`.

Logic backend:

- Gunakan `updateOrCreate` berdasarkan `fcm_token` agar tidak ada duplikasi data.
- Pastikan token hanya bisa di-bind ke 1 user aktif pada saat yang sama.
- Update `last_active` setiap register/login.

### 1.2.1 Ambil Daftar Device Aktif

- **Method:** `GET`
- **Endpoint:** `/devices`
- **Auth:** `Bearer Token`
- **Response Success (200):**

```json
{
    "status": "success",
    "message": "Daftar device berhasil diambil",
    "data": [
        {
            "id": 11,
            "device_name": "iPhone 15 Pro",
            "device_type": "ios",
            "last_active": "2026-04-12T09:00:00+08:00",
            "is_current_device": true
        }
    ]
}
```

### 1.3 Hapus Device Token (Logout)

Penting dilakukan saat user logout agar device tersebut tidak lagi menerima notifikasi milik user tersebut.

- **Method:** `DELETE`
- **Endpoint:** `/devices/revoke`
- **Request Body:**

```json
{
    "fcm_token": "token_yang_ingin_dihapus"
}
```

Keamanan endpoint revoke:

- Token yang dicabut harus milik user yang sedang login.
- Jika token tidak ditemukan pada user tersebut, kembalikan `404`.

### 1.4 Hapus Semua Device Token (Logout All Devices)

- **Method:** `DELETE`
- **Endpoint:** `/devices/revoke-all`
- **Auth:** `Bearer Token`
- **Response Success (200):**

```json
{
    "status": "success",
    "message": "Semua device berhasil dicabut",
    "data": {
        "revoked_count": 3
    }
}
```

### 1.5 Profil Pengguna Saat Ini

- **Method:** `GET`
- **Endpoint:** `/auth/me`
- **Auth:** `Bearer Token`

Contoh field penting pada response `data`:

```json
{
    "id": 1,
    "username": "novalia_yordan",
    "email": "nova@example.com",
    "nomor_kk": "5171012345678901",
    "profile_photo_url": "https://api.gpi-yehuda.org/storage/profile-photos/abc.jpg"
}
```

### 1.5.1 Upload Foto Profil Pengguna

- **Method:** `POST`
- **Endpoint:** `/auth/me/photo`
- **Auth:** `Bearer Token`
- **Content-Type:** `multipart/form-data`
- **Body:**
    - `photo`: required, image (`jpg`, `jpeg`, `png`, `webp`), max 5MB

Response sukses mengembalikan payload user terbaru, termasuk `profile_photo_url`.

### 1.6 Logout Akun

- **Method:** `POST`
- **Endpoint:** `/auth/logout`
- **Auth:** `Bearer Token`

## 2. Manajemen Event & Dokumentasi

Sama seperti sebelumnya, modul ini mengelola jadwal ibadah/kegiatan dan arsip dokumentasi hasil kegiatan.

### 2.1 Daftar Event (Jadwal)

- **Method:** `GET`
- **Endpoint:** `/events`
- **Query Params:**
    - `status`: `upcoming` (akan datang) atau `past` (arsip)
    - `page`: default `1`
    - `per_page`: default `10`, max `100`
    - `sort_by`: `date`, `created_at`
    - `sort_order`: `asc` atau `desc`

- **Response Success (200) - Paginated:**

```json
{
    "status": "success",
    "message": "Daftar event berhasil diambil",
    "data": [
        {
            "id": 14,
            "title": "Ibadah Raya Minggu",
            "date": "2026-04-12T09:00:00+08:00",
            "location": {
                "name": "Gedung Utama GPI Yehuda",
                "address": "Jl. Sunset Road No. 767, Denpasar, Bali",
                "latitude": -8.670458,
                "longitude": 115.212629,
                "place_id": "ChIJ-example-place-id",
                "maps_url": "https://maps.google.com/?q=-8.670458,115.212629"
            },
            "category": "Ibadah"
        }
    ],
    "meta": {
        "current_page": 1,
        "per_page": 10,
        "total": 42,
        "last_page": 5
    },
    "links": {
        "first": "https://api.gpi-yehuda.org/api/v1/events?page=1",
        "last": "https://api.gpi-yehuda.org/api/v1/events?page=5",
        "prev": null,
        "next": "https://api.gpi-yehuda.org/api/v1/events?page=2"
    }
}
```

### 2.2 Buat Event Baru (Admin Only)

- **Method:** `POST`
- **Endpoint:** `/events`
- **Request Body:**

```json
{
    "title": "Ibadah Raya Minggu",
    "description": "Ibadah rutin mingguan dengan tema Pengharapan.",
    "date": "2026-04-12T09:00:00+08:00",
    "location": {
        "name": "Gedung Utama GPI Yehuda",
        "address": "Jl. Sunset Road No. 767, Denpasar, Bali",
        "latitude": -8.670458,
        "longitude": 115.212629,
        "place_id": "ChIJ-example-place-id",
        "maps_url": "https://maps.google.com/?q=-8.670458,115.212629"
    },
    "category": "Ibadah"
}
```

Catatan kompatibilitas frontend maps:

- Jika frontend memakai place picker maps, kirim minimal `address`, `latitude`, dan `longitude`.
- `place_id` direkomendasikan untuk deduplikasi lokasi.
- Field `location` string lama tetap didukung sementara untuk client legacy.

### 2.3 Upload Dokumentasi Event (Admin Only)

- **Method:** `POST`
- **Endpoint:** `/events/{id}/documentation`
- **Content-Type:** `multipart/form-data`
- **Body:**
    - `files[]`: file image/video
    - `report_summary`: ringkasan laporan

Upload constraints:

- `files[]`: required, minimal 1 file, maksimal 20 file per request.
- Ukuran per file: maksimal 20MB.
- Total upload per request: maksimal 200MB.
- Mime type yang diizinkan: `image/jpeg`, `image/png`, `image/webp`, `video/mp4`, `video/quicktime`.
- File yang gagal validasi harus mengembalikan `422` dengan detail per file.

### 2.4 Download Semua Dokumentasi Event (Jemaat)

Jemaat dapat mengunduh seluruh dokumentasi pada satu event dalam bentuk file `.zip`.

- **Method:** `GET`
- **Endpoint:** `/events/{id}/documentation/download`
- **Auth:** `Bearer Token` (jemaat dan admin)
- **Response:** file binary `.zip`
- **Header Response:**
    - `Content-Type: application/zip`
    - `Content-Disposition: attachment; filename="event-{id}-documentation.zip"`

Catatan backend:

- Sistem menggabungkan semua file dokumentasi event berdasarkan `event_id`.
- Proses kompresi dilakukan saat request (on-demand) atau dari file zip cache jika sudah tersedia.
- Jika dokumentasi belum ada, kembalikan respons `404 Not Found` dengan pesan yang sesuai.
- Untuk file besar, gunakan stream download agar penggunaan memori tetap aman.

## 3. Pendaftaran Layanan (Service Registration)

Modul ini menggunakan template form dinamis yang dikelola admin. Jemaat hanya membaca template aktif, mengisi `form_data` sesuai field template, lalu menunggu approval admin.

### 3.1 Ambil Kategori Layanan

- **Method:** `GET`
- **Endpoint:** `/services/categories`
- **Response:**

```json
["baptisan", "pernikahan", "penyerahan_anak", "permohonan_doa"]
```

### 3.1.1 Ambil Semua Template Form Layanan

- **Method:** `GET`
- **Endpoint:** `/services/forms`
- **Auth:** `Bearer Token`
- **Response Success (200):**

```json
{
    "status": "success",
    "message": "Daftar template layanan berhasil diambil",
    "data": [
        {
            "id": 1,
            "category": "baptisan",
            "name": "Form Baptisan",
            "is_active": true,
            "fields": [
                { "key": "nama_lengkap", "type": "string", "required": true },
                { "key": "tanggal_lahir", "type": "string", "required": true }
            ]
        }
    ]
}
```

### 3.1.2 Ambil Detail Template Berdasarkan Kategori

- **Method:** `GET`
- **Endpoint:** `/services/forms/{category}`
- **Auth:** `Bearer Token`

### 3.2 Kirim Formulir Pendaftaran

- **Method:** `POST`
- **Endpoint:** `/services/apply`
- **Request Body:**

```json
{
    "category": "baptisan",
    "form_data": {
        "nama_lengkap": "Anak A",
        "tempat_lahir": "Denpasar",
        "tanggal_lahir": "2026-01-01",
        "nama_ayah": "Budi",
        "nama_ibu": "Sari"
    },
    "attachments": ["link_file_kk", "link_file_ktp"]
}
```

Catatan validasi dinamis:

- `category` harus merujuk ke template aktif.
- `form_data` diverifikasi secara runtime berdasarkan `fields` pada template.
- Jika field `required` pada template tidak dikirim, API mengembalikan `422 Validation Error`.
- `nomor_kk` jemaat wajib tersedia pada profil user sebelum submit layanan.
- `attachments` disimpan dalam kondisi terenkripsi (encryption at rest) untuk mencegah kebocoran data sensitif.

Relasi data jemaat dan service application:

- `service_applications.user_id` berelasi ke `users.id`.
- Sistem menyimpan `nomor_kk_snapshot` pada saat apply untuk menjaga konsistensi data administratif.

### 3.2.1 Simpan/Update Template Form Layanan (Admin Only)

- **Method:** `POST`
- **Endpoint:** `/services/forms`
- **Auth:** `Bearer Token` (admin)

- **Method:** `PUT`
- **Endpoint:** `/services/forms/{category}`
- **Auth:** `Bearer Token` (admin)

- **Method:** `DELETE`
- **Endpoint:** `/services/forms/{category}`
- **Auth:** `Bearer Token` (admin)

- **Request Body:**

```json
{
    "category": "konseling",
    "name": "Form Konseling",
    "is_active": true,
    "fields": [
        {
            "key": "nama_lengkap",
            "type": "string",
            "required": true,
            "label": "Nama Lengkap"
        },
        {
            "key": "jadwal_preferensi",
            "type": "string",
            "required": true,
            "label": "Jadwal Preferensi"
        },
        {
            "key": "butuh_anonim",
            "type": "boolean",
            "required": false,
            "label": "Butuh Anonim"
        }
    ]
}
```

### 3.3 Update Status Persetujuan (Admin Only)

- **Method:** `PATCH`
- **Endpoint:** `/services/applications/{id}/status`
- **Request Body:**

```json
{
    "status": "approved",
    "admin_note": "Jadwal baptisan disetujui untuk tanggal 20 Mei."
}
```

### 3.4 Export Sertifikat Pengajuan Layanan (PDF)

- **Method:** `GET`
- **Endpoint:** `/services/applications/{id}/certificate/pdf`
- **Auth:** `Bearer Token` (pemilik pengajuan atau admin)
- **Response:** file binary PDF (`application/pdf`)

Catatan:

- Dokumen ini berfungsi sebagai sertifikat/bukti pengajuan layanan jemaat.
- Isi sertifikat mencakup identitas jemaat, kategori layanan, status, dan `nomor_kk_snapshot`.

## 4. Notifikasi & Broadcast

### 4.1 Send Push Notification (Logic Backend)

Saat admin mengirim broadcast atau sistem mengirim pengingat otomatis:

1. Laravel mencari semua token di tabel `user_devices` yang berelasi dengan `user_id` target.
2. Laravel mengirim array berisi kumpulan token tersebut ke FCM.

- **Endpoint broadcast (admin):** `POST /notifications/broadcast`
- **Contoh Request Body:**

```json
{
    "title": "Pengingat Ibadah",
    "message": "Shalom, jangan lupa Ibadah Raya besok pukul 09:00 WITA.",
    "target_type": "all",
    "target_filters": {
        "role": "jemaat",
        "user_ids": [12, 31],
        "event_id": 14
    }
}
```

Ketentuan notification targeting:

- `target_type` wajib salah satu: `all`, `role`, `users`, `event_attendees`, `service_applicants`.
- Jika `target_type=role`, maka `target_filters.role` wajib diisi.
- Jika `target_type=users`, maka `target_filters.user_ids` wajib minimal 1 id.
- Jika `target_type=event_attendees`, maka `target_filters.event_id` wajib ada.
- Jika `target_type=service_applicants`, dapat memakai `target_filters.service_category` dan/atau `target_filters.service_status`.
- Backend wajib mencatat log jumlah token target, jumlah sukses, dan jumlah gagal kirim.
- Pengiriman broadcast wajib dijalankan melalui Queue Job agar request API tetap ringan.

Notifikasi otomatis lintas modul service application:

- Saat jemaat mengirim `POST /services/apply`, sistem mengirim notifikasi ke semua admin aktif.
- Saat admin mengubah status lewat `PATCH /services/applications/{id}/status`, sistem mengirim notifikasi ke jemaat pemilik pengajuan.

Contoh targeting lintas modul service application:

```json
{
    "title": "Status Layanan",
    "message": "Pengajuan baptisan yang disetujui sudah bisa dijadwalkan.",
    "target_type": "service_applicants",
    "target_filters": {
        "service_category": "baptisan",
        "service_status": "approved"
    }
}
```

## 5. Monitoring Endpoint

Endpoint monitoring digunakan untuk health-check oleh sistem observability, load balancer, dan container orchestration.

- **Method:** `GET`
- **Endpoint:** `/health`
- **Auth:** publik (tanpa token)
- **Response Success (200):**

```json
{
    "status": "ok"
}
```

## 6. Rate Limiting Policy

Untuk mencegah abuse, endpoint menerapkan pembatasan request:

1. `POST /auth/login`: maksimal 5 request per menit per IP.
2. `POST /auth/register`: maksimal 3 request per menit per IP.
3. `POST /notifications/broadcast`: maksimal 10 request per menit per admin.
4. Endpoint umum lainnya: maksimal 60 request per menit per user/token.

Jika limit terlampaui, API mengembalikan `429 Too Many Requests`.

Header rate-limit yang direkomendasikan:

- `X-RateLimit-Limit`
- `X-RateLimit-Remaining`
- `Retry-After`

## Lampiran: Skema Database (Laravel Migration)

Untuk mendukung spesifikasi multi-device, buat tabel baru berikut.

- **File:** `xxxx_xx_xx_create_user_devices_table.php`

```php
Schema::create('user_devices', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->onDelete('cascade');
        $table->string('fcm_token')->unique(); // Token unik per instalasi
        $table->string('device_name')->nullable(); // Contoh: Samsung S24
        $table->enum('device_type', ['android', 'ios', 'web']);
        $table->timestamp('last_active')->useCurrent();
        $table->timestamps();
});
```

## Kode Status Respons

| Code                       | Keterangan                                          |
| -------------------------- | --------------------------------------------------- |
| 200 OK                     | Permintaan berhasil.                                |
| 201 Created                | Device baru berhasil didaftarkan.                   |
| 204 No Content             | Berhasil menghapus resource tanpa body respons.     |
| 400 Bad Request            | Format request tidak sesuai spesifikasi.            |
| 401 Unauthorized           | Session habis, silakan login kembali.               |
| 403 Forbidden              | Role user tidak diizinkan mengakses endpoint ini.   |
| 404 Not Found              | Dokumentasi event tidak ditemukan / belum tersedia. |
| 405 Method Not Allowed     | HTTP method tidak didukung untuk endpoint ini.      |
| 409 Conflict               | Konflik data (misal duplikasi resource unik).       |
| 415 Unsupported Media Type | Tipe file upload tidak didukung.                    |
| 422 Validation Error       | Input tidak valid (misal: token tidak disertakan).  |
| 429 Too Many Requests      | Terlalu banyak request, coba lagi nanti.            |
| 500 Server Error           | Terjadi kesalahan internal pada server.             |

Dokumen ini diperbarui untuk memastikan jemaat GPI Yehuda menerima notifikasi di seluruh perangkat yang mereka gunakan.

## Tips Implementasi

1. Di Flutter: panggil endpoint `POST /devices/register` di `initState` halaman utama atau segera setelah login berhasil.
2. Di Laravel: saat admin membuat event baru, gunakan Job/Queue untuk mengirim notifikasi ke semua token di tabel `user_devices` agar performa API tetap cepat.

## Resource & Request Layer (Laravel)

Agar implementasi rapi dan konsisten, gunakan pemisahan berikut:

1. **Form Request** untuk validasi input per endpoint.
2. **API Resource** untuk serialisasi output response schema.
3. **Service Class** untuk business logic (device binding, zip generation, broadcast targeting).
4. **Policy/Gate** untuk rule otorisasi admin vs jemaat.

Contoh struktur minimal:

- `app/Http/Requests/Devices/RegisterDeviceRequest.php`
- `app/Http/Requests/Events/UploadDocumentationRequest.php`
- `app/Http/Resources/EventResource.php`
- `app/Http/Resources/EventCollection.php`
- `app/Services/DeviceRegistrationService.php`
- `app/Services/EventDocumentationZipService.php`
- `app/Services/NotificationTargetingService.php`

## Clean Code Implementation

Prinsip implementasi yang wajib diikuti:

1. Controller tipis: hanya orkestrasi request, auth, dan response.
2. Hindari query di controller: gunakan service/repository (jika diperlukan).
3. Gunakan nama method yang eksplisit, misalnya `registerDevice`, `revokeDevice`, `streamDocumentationZip`.
4. Seluruh side effect berat (zip besar, push notification massal) dipindahkan ke Job/Queue.
5. Setiap endpoint wajib punya minimal 1 feature test sukses + 1 feature test gagal.
6. Logging terstruktur: simpan `trace_id`, `user_id`, endpoint, status code, dan durasi request.

## Logging & Trace ID

Setiap request wajib memiliki `trace_id` unik yang dibuat di middleware.

Informasi minimal yang dicatat ke log:

1. `trace_id`
2. `user_id` (nullable untuk guest)
3. `endpoint`
4. `status_code`
5. `duration_ms`

Nilai `trace_id` sebaiknya ikut dikembalikan pada response error untuk memudahkan investigasi issue dari sisi QA/Frontend.

## Strategi Pengujian API (Laravel)

Bagian ini melengkapi spesifikasi agar siap untuk quality gate CI/CD.

### 1. Unit Test (Fokus Logic)

Target unit test:

1. Logic `updateOrCreate` pada registrasi device token tidak membuat duplikasi `fcm_token`.
2. Service builder ZIP mengumpulkan file sesuai `event_id` yang diminta.
3. Filter role/permission helper mengembalikan hasil benar untuk admin vs jemaat.

Contoh skenario unit test penting:

- Saat token yang sama didaftarkan ulang dengan `device_name` baru, record lama ter-update (bukan insert baru).
- Saat event tidak punya dokumentasi, service ZIP melempar exception domain yang dipetakan ke `404`.

### 2. Feature Test (Fokus Endpoint)

Gunakan `php artisan test` dengan database testing (`RefreshDatabase`).

Daftar minimum feature test yang wajib ada:

1. `POST /auth/register` sukses dengan `fcm_token`.
2. `POST /auth/login` sukses dan mengembalikan bearer token.
3. `GET /auth/me` sukses pada token valid, gagal `401` pada token invalid.
4. `POST /auth/logout` sukses invalidasi sesi aktif.
5. `GET /devices` mengembalikan daftar device milik user.
6. `POST /devices/register`:
    - sukses (`201/200`) dengan token valid.
    - gagal `422` jika `fcm_token` kosong.
7. `DELETE /devices/revoke`:
    - sukses menghapus/mencabut token device user aktif.
    - gagal `401` jika tanpa auth.
8. `DELETE /devices/revoke-all` sukses mencabut semua device user.
9. `POST /events`:
    - sukses untuk admin.
    - gagal `403` untuk jemaat.
10. `POST /events/{id}/documentation`:
    - sukses upload multipart untuk admin.
    - validasi format file (misal hanya image/video yang diizinkan).
11. `GET /events/{id}/documentation/download`:
    - sukses `200` dan header `Content-Type: application/zip`.
    - `404` jika dokumentasi kosong.
    - `401` jika tanpa token.
12. `POST /notifications/broadcast`:
    - sukses untuk admin.
    - gagal `403` untuk jemaat.
13. `GET /health` selalu mengembalikan `200` dengan status `ok`.

### 3. Contoh Struktur Nama Test

- `tests/Unit/DeviceRegistrationServiceTest.php`
- `tests/Unit/EventDocumentationZipServiceTest.php`
- `tests/Feature/Auth/LoginTest.php`
- `tests/Feature/Devices/RegisterDeviceTest.php`
- `tests/Feature/Events/DownloadEventDocumentationTest.php`

### 4. Command Test yang Direkomendasikan

```bash
php artisan test
php artisan test --testsuite=Feature
php artisan test --filter=DownloadEventDocumentationTest
```

### 5. Kriteria Lulus QA (Definition of Done)

1. Seluruh endpoint utama lolos skenario sukses + gagal (auth, role, validasi).
2. Download ZIP tervalidasi secara konten (file sesuai event) dan header respons.
3. Tidak ada duplikasi device token untuk user yang sama pada skenario login berulang.
4. Pengiriman notifikasi ke multi-device tervalidasi minimal pada environment staging.
