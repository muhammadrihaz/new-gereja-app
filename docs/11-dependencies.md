# 11 - Dependencies

## PHP Dependencies (Composer)

### Production (`require`)

| Package                   | Version | Fungsi                                                                   |
| ------------------------- | ------- | ------------------------------------------------------------------------ |
| `php`                     | ^8.3    | PHP runtime minimum                                                      |
| `laravel/framework`       | ^13.0   | Laravel framework core                                                   |
| `laravel/sanctum`         | ^4.3    | API token authentication                                                 |
| `laravel/tinker`          | ^3.0    | REPL untuk debugging                                                     |
| `barryvdh/laravel-dompdf` | ^3.1    | Generasi PDF dari view Blade (sertifikat layanan)                        |
| `google/auth`             | ^1.52   | Google OAuth2 — digunakan untuk mendapatkan access token FCM v1          |
| `predis/predis`           | ^3.4    | Redis PHP client — digunakan untuk cache dan queue jika Redis diaktifkan |
| `resend/resend-php`       | ^1.1    | Email delivery service via Resend API                                    |

### Development (`require-dev`)

| Package                | Version  | Fungsi                                   |
| ---------------------- | -------- | ---------------------------------------- |
| `fakerphp/faker`       | ^1.23    | Data generator untuk testing dan seeding |
| `laravel/pail`         | ^1.2.5   | Real-time log viewer di terminal         |
| `laravel/pint`         | ^1.27    | PHP code formatter (PSR-12 compatible)   |
| `mockery/mockery`      | ^1.6     | Mocking framework untuk unit test        |
| `nunomaduro/collision` | ^8.6     | Better error reporting untuk CLI         |
| `phpunit/phpunit`      | ^12.5.12 | PHP unit testing framework               |

## NPM Dependencies

| Package               | Fungsi                                                                     |
| --------------------- | -------------------------------------------------------------------------- |
| `concurrently`        | Menjalankan multiple commands paralel (digunakan di `composer dev` script) |
| `vite`                | Build tool frontend                                                        |
| `laravel-vite-plugin` | Integrasi Vite dengan Laravel                                              |

## Flutter Dependencies (pubspec.yaml)

### Production

| Package                       | Version  | Fungsi                                          |
| ----------------------------- | -------- | ----------------------------------------------- |
| `flutter`                     | SDK      | Flutter framework                               |
| `cupertino_icons`             | ^1.0.8   | iOS style icons                                 |
| `http`                        | ^1.5.0   | HTTP client untuk API calls                     |
| `shared_preferences`          | ^2.5.3   | Key-value storage lokal (auth token, role)      |
| `image_picker`                | ^1.1.2   | Pemilihan foto dari galeri/kamera (profil foto) |
| `file_picker`                 | ^8.0.7   | Pemilihan file umum                             |
| `firebase_core`               | ^3.4.0   | Firebase initialization                         |
| `firebase_messaging`          | ^15.2.10 | Firebase Cloud Messaging (push notification)    |
| `flutter_local_notifications` | ^17.1.2  | Menampilkan notifikasi lokal di device          |
| `intl`                        | ^0.20.2  | Internationalization, formatting tanggal        |
| `web`                         | ^1.1.0   | Web-specific API access                         |
| `cached_network_image`        | ^3.4.1   | Cache gambar dari network                       |
| `shimmer`                     | ^3.0.0   | Loading skeleton animation                      |
| `timeago`                     | ^3.7.1   | Relative time formatting ("2 jam lalu")         |

### Development

| Package         | Version | Fungsi                      |
| --------------- | ------- | --------------------------- |
| `flutter_test`  | SDK     | Flutter testing framework   |
| `flutter_lints` | ^6.0.0  | Lint rules saat development |

## Docker Dependencies

| Service  | Image                  | Version |
| -------- | ---------------------- | ------- |
| PHP-FPM  | php:8.4-fpm-alpine     | 8.4     |
| Nginx    | nginx:1.27-alpine      | 1.27    |
| MariaDB  | mariadb:11.4           | 11.4    |
| Redis    | redis:7-alpine         | 7       |
| Mailpit  | axllent/mailpit:latest | latest  |
| Composer | composer:2             | 2       |

### PHP Extensions (Dockerfile)

| Extension      | Fungsi                              |
| -------------- | ----------------------------------- |
| `pdo_mysql`    | MySQL/MariaDB database driver       |
| `bcmath`       | Arbitrary precision math            |
| `intl`         | Internationalization                |
| `zip`          | ZIP archive support (download docs) |
| `opcache`      | PHP bytecode caching                |
| `redis` (PECL) | Redis extension                     |

## Third-Party Services

| Service        | Penggunaan                        | Config                                            |
| -------------- | --------------------------------- | ------------------------------------------------- |
| Firebase / FCM | Push notifications                | `config/services.php` → `fcm`                     |
| Resend         | Email delivery (production)       | `MAIL_MAILER=resend` + `RESEND_API_KEY`           |
| Google Cloud   | Service Account untuk FCM v1 Auth | `FCM_CREDENTIALS_JSON` / `FCM_CREDENTIALS_BASE64` |
| Mailpit        | Email testing (development)       | Port 1025 SMTP, 8025 Web UI                       |
