# GPI Yehuda Flutter App

Flutter app ini mengonsumsi Laravel API pada folder api dengan role-based dashboard:

- Admin: web-first dashboard untuk monitoring operasional dan manajemen profil gereja.
- Jemaat: mobile-first dashboard untuk aktivitas jemaat (event dan pengajuan layanan).

## Fitur Utama

- Login lintas device dengan token Sanctum + register device.
- Dashboard berbeda otomatis berdasarkan role user saat login.
- Dark mode (manual toggle).
- Fallback logo otomatis:
  - Light mode: assets/image/logo_1.png
  - Dark mode: assets/image/logo_2.png
- Jika API mengirim logo URL di church profile, aplikasi akan memakai logo dari API.
- Mode FCM dummy siap dipakai jika Firebase belum di-setup.
- Admin dashboard memiliki panel Broadcast Notification untuk uji kirim notifikasi dari web.

## Menjalankan App

Install dependency:

```bash
flutter pub get
```

Run mobile (prioritas utama):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

Run web (prioritas admin):

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

Testing sementara di Chrome saja:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

Catatan:

- Mode dummy FCM dipakai otomatis jika token Firebase asli belum tersedia.
- Ini memastikan flow login lintas device, register device, dan broadcast API tetap bisa diuji end-to-end.

## Role-based Routing

1. Login memanggil POST /auth/login.
2. Token disimpan lokal.
3. App memanggil GET /auth/me untuk validasi sesi.
4. Role admin -> Admin Dashboard.
5. Role jemaat -> Jemaat Dashboard.

## Akun Testing (Seeder Laravel)

Jalankan seeder di backend API:

```bash
cd api
php artisan db:seed --force
```

Kredensial uji Flutter:

- Admin:
  - email: admin@example.com
  - password: password123
- Jemaat:
  - email: jemaat@example.com
  - password: password123

Catatan:

- Input FCM token pada UI login sudah dihapus.
- Token device/FCM dikelola otomatis di background.

## Catatan FCM

Dokumentasi integrasi FCM Flutter dan API Laravel tersedia di:

- documents/flutter_fcm_laravel_integration.md
# new-gereja-app
