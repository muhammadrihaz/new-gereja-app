# 01 - Project Overview

## Tujuan Aplikasi

Aplikasi manajemen gereja (Church Management System) yang berfungsi sebagai platform digital untuk mengelola data jemaat, kegiatan gereja, berita, layanan gereja, dan notifikasi push. Dirancang sebagai solusi mobile-first menggunakan Flutter dengan backend Laravel REST API.

## Masalah yang Diselesaikan

1. **Pengelolaan data jemaat manual** → Digitalisasi data anggota gereja dan kartu keluarga (KK)
2. **Informasi kegiatan tersebar** → Sentralisasi event, berita, dan pengumuman gereja
3. **Pengajuan layanan birokrasi** → Digitalisasi proses pengajuan layanan gereja (baptis, nikah, dll)
4. **Komunikasi tidak efektif** → Push notification dan broadcast untuk seluruh jemaat
5. **Pencatatan KK manual** → Sistem registrasi dan verifikasi Kartu Keluarga digital

## User Flow

```mermaid
flowchart TD
    A[Buka Aplikasi] --> B{Sudah Login?}
    B -->|Ya| C{Role?}
    B -->|Tidak| D[Login / Register]
    D --> E[Verifikasi Nomor KK + Nama]
    E --> F[Buat Akun / Masuk]
    F --> C
    C -->|Admin| G[Admin Dashboard]
    C -->|Jemaat| H[Jemaat Dashboard]
    G --> G1[Kelola Jemaat]
    G --> G2[Kelola Event]
    G --> G3[Kelola Berita]
    G --> G4[Kelola Layanan]
    G --> G5[Kelola KK]
    G --> G6[Broadcast Notifikasi]
    G --> G7[Profil Gereja]
    H --> H1[Lihat Event]
    H --> H2[Baca Berita]
    H --> H3[Ajukan Layanan]
    H --> H4[Data Keluarga]
    H --> H5[Edit Profil]
    H --> H6[Inbox Notifikasi]
```

## Aktor

| Aktor      | Role     | Deskripsi                                                                                 |
| ---------- | -------- | ----------------------------------------------------------------------------------------- |
| **Admin**  | `admin`  | Pengelola gereja. Dapat CRUD jemaat, event, berita, layanan, KK, dan broadcast notifikasi |
| **Jemaat** | `jemaat` | Anggota gereja. Dapat melihat event/berita, mengajukan layanan, dan melihat data keluarga |

## Fitur Utama

### Authentication & Authorization

- Registrasi dengan verifikasi Nomor KK + Nama
- Login via username/email + password
- Token-based auth (Laravel Sanctum)
- Role-based access: `admin` dan `jemaat`

### Manajemen Jemaat (Admin)

- CRUD data jemaat
- Filter berdasarkan KK, status (active/jemaat/simpatisan)
- Data keluarga berdasarkan nomor KK

### Manajemen Event

- CRUD event gereja dengan kategori
- Upload dokumentasi event (file/foto)
- Download dokumentasi sebagai ZIP
- Auto-archive event yang expired
- Push reminder H-2 dan H-1

### Manajemen Berita

- CRUD berita dengan cover image
- Upload lampiran file
- Download lampiran sebagai ZIP
- Filter berdasarkan status published

### Layanan Gereja

- Template form dinamis per kategori layanan
- Pengajuan layanan oleh jemaat
- Tracking status: pending → approved/rejected
- Export aplikasi layanan ke CSV
- Generate sertifikat layanan (PDF)

### Registrasi Kartu Keluarga

- CRUD registrasi KK
- Verifikasi KK sebelum registrasi
- Relasi KK → anggota keluarga

### Notifikasi

- Push notification via FCM v1
- Email notification (fallback)
- Broadcast ke semua/role/users tertentu
- Inbox notifikasi personal
- Tracking read/unread

### Profil Gereja

- Kelola profil gereja (nama, alamat, logo, metadata)

## Arsitektur Tinggi

```mermaid
graph TB
    subgraph "Frontend (Flutter)"
        A[Flutter App] --> B[ApiClient]
        A --> C[SessionController]
        A --> D[Firebase Messaging]
    end

    subgraph "Backend (Laravel 13)"
        E[Nginx / Apache] --> F[Laravel API v1]
        F --> G[Sanctum Auth]
        F --> H[Controllers]
        H --> I[Services]
        I --> J[Models / Eloquent]
        J --> K[(MariaDB)]
        I --> L[FCM v1 API]
        I --> M[SMTP / Resend]
        F --> N[Queue Worker]
        N --> O[Jobs]
        F --> P[Scheduler]
        P --> Q[Commands]
    end

    subgraph "Infrastructure"
        R[Docker Compose]
        R --> S[PHP-FPM 8.4]
        R --> T[MariaDB 11.4]
        R --> U[Redis 7]
        R --> V[Mailpit]
        R --> W[Nginx 1.27]
    end

    B --> F
    D --> L
```

## Dependency Utama

### Backend (Laravel)

| Package                        | Fungsi                                 |
| ------------------------------ | -------------------------------------- |
| `laravel/framework` ^13.0      | Framework utama                        |
| `laravel/sanctum` ^4.3         | Token-based API authentication         |
| `barryvdh/laravel-dompdf` ^3.1 | PDF generation (sertifikat layanan)    |
| `google/auth` ^1.52            | Google OAuth untuk FCM service account |
| `predis/predis` ^3.4           | Redis client untuk cache dan queue     |
| `resend/resend-php` ^1.1       | Email delivery via Resend              |

### Frontend (Flutter)

| Package                               | Fungsi                                |
| ------------------------------------- | ------------------------------------- |
| `firebase_core` ^3.4.0                | Firebase initialization               |
| `firebase_messaging` ^15.2.10         | Push notifications                    |
| `flutter_local_notifications` ^17.1.2 | Local notification display            |
| `http` ^1.5.0                         | HTTP client untuk API                 |
| `shared_preferences` ^2.5.3           | Penyimpanan token lokal               |
| `cached_network_image` ^3.4.1         | Cache gambar jaringan                 |
| `image_picker` ^1.1.2                 | Ambil foto profil                     |
| `shimmer` ^3.0.0                      | Loading skeleton                      |
| `intl` ^0.20.2                        | Internationalization / format tanggal |
