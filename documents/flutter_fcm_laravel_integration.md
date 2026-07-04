# Flutter + Laravel API + FCM Integration Guide

Panduan ini untuk aplikasi Flutter di root project agar terhubung ke API Laravel pada folder api, dengan dukungan login lintas device dan notifikasi FCM.

## 1. Base URL API untuk Flutter

Jalankan Flutter dengan base URL environment:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

Contoh untuk Android emulator (Docker API di host):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

## 2. Login Lintas Device

Flow yang sudah dipakai aplikasi Flutter:

1. Login via POST /auth/login.
2. Simpan token Sanctum di local storage.
3. Register device via POST /devices/register.
4. Header X-Device-Token dipakai saat GET /devices agar current device bisa ditandai.

Catatan:

- Jika token FCM belum tersedia, aplikasi menggunakan token device fallback untuk development.
- Pada produksi, token fallback harus diganti dengan token Firebase Messaging asli.

## 3. Setup FCM di Flutter

### 3.0 Mode Dummy (Sementara Firebase Belum Setup)

Jika Firebase belum siap, aplikasi memakai token dummy secara otomatis.

- Sumber token: device identity local.
- Tetap dikirim ke endpoint `POST /devices/register` agar flow lintas device bisa diuji.
- Admin dapat uji endpoint broadcast dari dashboard web untuk verifikasi API contract.

Mode ini cocok untuk fase integrasi awal agar tim frontend/backend dapat lanjut tanpa blocker Firebase.

Tambahkan package (jika belum):

```bash
flutter pub add firebase_core firebase_messaging
```

Langkah setup platform:

1. Android:

- Letakkan google-services.json di android/app/.
- Aktifkan plugin google-services di Gradle.

2. iOS:

- Letakkan GoogleService-Info.plist di ios/Runner/.
- Aktifkan Push Notifications capability.
- Aktifkan Background Modes > Remote notifications.

3. Web:

- Konfigurasikan firebase config pada web/index.html.
- Tambahkan firebase-messaging-sw.js jika memakai background notifications.

Contoh inisialisasi token di Flutter:

```dart
await Firebase.initializeApp();
final messaging = FirebaseMessaging.instance;
await messaging.requestPermission();
final token = await messaging.getToken();
```

Setelah token didapat, kirim ke API:

- POST /devices/register
- body: fcm_token, device_type, device_name

## 4. Setup FCM di Laravel API

Pastikan env backend:

```env
FCM_ENABLED=true
FCM_SERVER_KEY=YOUR_FCM_SERVER_KEY
FCM_PROJECT_ID=YOUR_PROJECT_ID
FCM_ENDPOINT=https://fcm.googleapis.com/fcm/send
EMAIL_NOTIFICATIONS_ENABLED=false
```

Verifikasi:

1. Login dari Flutter dan register device sukses.
2. Kirim test broadcast dari admin endpoint POST /notifications/broadcast.
3. Cek notification_dispatch_logs untuk status sent/failed/queued dan trace_id.

## 5. Storage Environment Policy

1. Localhost/Docker:

- FILESYSTEM_DISK=local
- jalankan php artisan storage:link

2. Staging/Production:

- FILESYSTEM_DISK=s3
- gunakan object storage/bucket (S3 compatible)
- isi AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION, AWS_BUCKET, AWS_ENDPOINT sesuai provider

## 6. Role-based Dashboard Behavior

Aplikasi Flutter ini membedakan tampilan berdasarkan role:

- Admin dashboard:
  - Fokus web dan monitoring operasional (health, template, devices, profile gereja, event)
- Jemaat dashboard:
  - Fokus mobile dan aktivitas jemaat (event + apply layanan)

Jika field logo dari API kosong:

- Light mode menggunakan assets/image/logo_1.png
- Dark mode menggunakan assets/image/logo_2.png

## 7. Checklist Ready for Flutter

- GET /health mengembalikan flutter_ready=true.
- Semua endpoint protected menggunakan Bearer token.
- Semua response menyediakan trace_id untuk tracing issue.
- Login lintas device dan register device sudah aktif.
- API push notification lintas modul sudah tersedia.

## 8. Production Readiness Checklist (Setelah Dummy)

1. Ganti token dummy dengan token Firebase Messaging asli (`firebase_messaging`).
2. Aktifkan FCM backend env di Laravel (`FCM_ENABLED=true` + key valid).
3. Uji notifikasi foreground/background pada Android, iOS, dan web.
4. Validasi `notification_dispatch_logs` untuk status sent/failed/queued + trace_id.
5. Pastikan object storage aktif di staging/prod untuk file publik.
