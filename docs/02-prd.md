# 02 - Product Requirement Document (PRD)

## Product Vision

Menjadi platform digital gereja terdepan yang menyederhanakan administrasi gereja, memperkuat komunikasi antara pengurus dan jemaat, serta mendigitalisasi layanan-layanan gereja melalui aplikasi mobile yang mudah digunakan.

## Goals

1. **Digitalisasi Data Jemaat** — Mengelola data anggota gereja dan kartu keluarga secara digital
2. **Sentralisasi Informasi** — Menyediakan satu platform untuk event, berita, dan pengumuman
3. **Otomasi Layanan** — Mendigitalisasi proses pengajuan layanan gereja (baptis, nikah, sidi, dll)
4. **Komunikasi Real-time** — Push notification dan broadcast untuk informasi penting
5. **Pelacakan Keluarga** — Menghubungkan anggota keluarga melalui nomor Kartu Keluarga

## Business Rules

### Registrasi & Autentikasi

- Calon pengguna **wajib** memiliki Nomor KK yang sudah terdaftar di sistem
- Nama lengkap harus cocok dengan nama kepala keluarga ATAU anggota keluarga yang sudah terdaftar
- Setiap user memiliki role: `admin` atau `jemaat`
- Default role registrasi adalah `jemaat`
- Login bisa menggunakan username atau email

### Manajemen Jemaat

- Hanya admin yang dapat menambah/edit/hapus data jemaat
- Jemaat dengan pengajuan layanan aktif (status `pending`) tidak dapat dihapus
- Status jemaat: `active`, `jemaat`, `simpatisan`
- Jenis kelamin: `L` (Laki-laki), `P` (Perempuan)

### Event

- Event memiliki waktu mulai (`start_at`) dan selesai (`end_at`)
- Event expired otomatis di-archive setiap 15 menit
- Jemaat hanya bisa melihat event yang belum di-archive dan belum berakhir > 24 jam
- Admin bisa melihat semua event termasuk archived
- Jika admin update `end_at` ke masa depan, event di-revive dari archive
- Reminder push dikirim H-2 dan H-1

### Berita

- Berita memiliki `published_at` — hanya berita yang sudah published yang tampil ke jemaat
- Lampiran berita disimpan di disk `public`
- Penghapusan berita otomatis menghapus file lampiran

### Layanan Gereja

- Template form dinamis: admin mendefinisikan field per kategori layanan
- Field types: `string`, `date`, `number`, `boolean`, `select`
- Validasi form data dilakukan secara dinamis berdasarkan template
- Nomor KK wajib ada di profil user sebelum mengajukan layanan
- Status aplikasi: `pending` → `approved` / `rejected`
- Admin mendapat notifikasi saat ada pengajuan baru
- Jemaat mendapat notifikasi saat status berubah

### Kartu Keluarga

- Nomor KK unik, minimal 16 karakter
- KK tidak dapat dihapus jika masih ada anggota keluarga terdaftar
- Satu KK bisa memiliki banyak anggota (relasi via `nomor_kk`)

### Notifikasi

- FCM token dikelola per device
- Token yang unregistered otomatis dihapus dari system
- Broadcast bisa ditargetkan ke: `all`, `role`, `users`, `event_attendees`, `service_applicants`
- Notifikasi email adalah fallback jika FCM tidak aktif
- Notifikasi memiliki status read/unread

## Functional Requirements

### FR-01: Registrasi User

- User mengisi username, password, nama, nomor KK
- Sistem verifikasi nomor KK dan nama terhadap database KK
- Jika valid, akun dibuat dengan role `jemaat`
- FCM token didaftarkan

### FR-02: Login User

- User login dengan username/email + password
- Sistem mengembalikan Sanctum token
- FCM token diperbarui

### FR-03: Profil User

- User dapat melihat dan update profil
- Upload foto profil
- Lihat data keluarga (anggota dengan KK yang sama)

### FR-04: Manajemen Event (Admin)

- CRUD event dengan kategori, lokasi, waktu mulai/selesai
- Upload dokumentasi event (multi-file, max 200MB per request)
- Download semua dokumentasi sebagai ZIP

### FR-05: Lihat Event (Jemaat)

- Daftar event aktif/upcoming
- Filter berdasarkan kategori, status, search
- Download dokumentasi event

### FR-06: Manajemen Berita (Admin)

- CRUD berita dengan cover image dan konten
- Upload lampiran file
- Publish/unpublish

### FR-07: Baca Berita (Jemaat)

- Daftar berita published
- Detail berita dengan lampiran
- Download lampiran sebagai ZIP

### FR-08: Template Layanan (Admin)

- CRUD template form per kategori layanan
- Konfigurasi field dinamis (key, type, required, options)
- Aktifkan/nonaktifkan template

### FR-09: Pengajuan Layanan (Jemaat)

- Pilih kategori layanan
- Isi form sesuai template
- Submit pengajuan
- Lihat daftar pengajuan dan statusnya

### FR-10: Review Layanan (Admin)

- Lihat semua pengajuan
- Update status (approved/rejected)
- Tambah catatan admin
- Export ke CSV

### FR-11: Manajemen KK (Admin)

- CRUD registrasi Kartu Keluarga
- Lihat anggota keluarga per KK

### FR-12: Notifikasi

- Admin broadcast notifikasi ke target tertentu
- Inbox notifikasi personal
- Mark read/unread
- Badge count unread

### FR-13: Device Management

- Register FCM device token
- Refresh token saat FCM token berubah
- Revoke device (single/all)

### FR-14: Profil Gereja (Admin)

- Kelola profil gereja (nama, alamat, telepon, email, logo, metadata)

## Non-Functional Requirements

| Requirement       | Detail                                                                                        |
| ----------------- | --------------------------------------------------------------------------------------------- |
| **Performance**   | API response < 500ms untuk operasi standar                                                    |
| **Scalability**   | Mendukung queue worker untuk job async                                                        |
| **Security**      | Sanctum token auth, password hashing (bcrypt 12 rounds), encrypted attachments, rate limiting |
| **Availability**  | Health check endpoint, Docker containerized                                                   |
| **Compatibility** | Flutter multiplatform: Android, iOS, Web, Linux, macOS, Windows                               |
| **Observability** | API activity logging, trace ID per request                                                    |
| **Caching**       | Cache 10 menit untuk kategori dan template                                                    |

## User Stories

| ID    | Sebagai      | Saya ingin                              | Sehingga                                   |
| ----- | ------------ | --------------------------------------- | ------------------------------------------ |
| US-01 | Calon jemaat | Mendaftar akun dengan nomor KK          | Saya bisa mengakses layanan gereja digital |
| US-02 | Jemaat       | Melihat event gereja yang akan datang   | Saya tidak melewatkan kegiatan             |
| US-03 | Jemaat       | Membaca berita terbaru                  | Saya tahu perkembangan gereja              |
| US-04 | Jemaat       | Mengajukan layanan baptis               | Saya tidak perlu datang ke kantor gereja   |
| US-05 | Jemaat       | Melihat status pengajuan layanan        | Saya tahu progres pengajuan                |
| US-06 | Jemaat       | Melihat anggota keluarga yang terdaftar | Saya bisa validasi data keluarga           |
| US-07 | Admin        | Mengelola data jemaat                   | Database jemaat selalu up-to-date          |
| US-08 | Admin        | Membuat event gereja                    | Jemaat mendapat info event terbaru         |
| US-09 | Admin        | Broadcast notifikasi                    | Informasi penting sampai ke semua jemaat   |
| US-10 | Admin        | Review pengajuan layanan                | Proses approval berjalan efisien           |
| US-11 | Admin        | Mengelola registrasi KK                 | Data KK gereja terorganisir                |
| US-12 | Admin        | Export data pengajuan ke CSV            | Mudah membuat laporan                      |

## Acceptance Criteria

### Registrasi

- ✅ User tidak bisa registrasi tanpa nomor KK yang valid
- ✅ User tidak bisa registrasi jika nama tidak cocok dengan data KK
- ✅ Setelah registrasi, user mendapat token dan otomatis login

### Event

- ✅ Event expired otomatis di-archive
- ✅ Jemaat tidak bisa melihat event yang sudah di-archive
- ✅ Reminder terkirim H-2 dan H-1

### Layanan

- ✅ Form validasi sesuai template dinamis
- ✅ Notifikasi terkirim ke admin saat pengajuan baru
- ✅ Notifikasi terkirim ke jemaat saat status berubah

## Success Metrics

| Metric                          | Target                         |
| ------------------------------- | ------------------------------ |
| Registrasi jemaat digital       | > 80% jemaat aktif             |
| Penggunaan fitur event          | > 50% jemaat membuka event     |
| Pengajuan layanan online        | > 60% layanan diajukan via app |
| Push notification delivery rate | > 90%                          |
| Response time API               | p95 < 500ms                    |

## Future Improvements

1. **Google Sign-In** — Integrasi OAuth Google (placeholder sudah ada di Flutter)
2. **Kehadiran / Attendance** — Tracking kehadiran di event (placeholder di NotificationTargetingService)
3. **Chat / Messaging** — Komunikasi langsung antar jemaat/admin
4. **Perpuluhan / Tithe Management** — Pencatatan dan tracking persembahan
5. **Jadwal Ibadah** — Kalender ibadah mingguan/bulanan
6. **Multi-church Support** — Satu platform untuk banyak gereja
7. **Analytics Dashboard** — Statistik penggunaan, kehadiran, layanan
8. **Offline Mode** — Akses data saat tidak ada koneksi internet
9. **Multi-language** — Bahasa Indonesia + English
10. **PWA Optimization** — Progressive Web App yang lebih optimal (scaffold sudah ada)
