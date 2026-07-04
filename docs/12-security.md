# 12 - Security Analysis

## Temuan & Rekomendasi

### 🔴 CRITICAL

#### SEC-01: Hardcoded Credentials di Flutter

- **File**: `lib/src/core/environment.dart`
- **Problem**: Credentials testing di-hardcode dalam source code
  ```dart
  static const String localAdminEmail = 'admin@example.com';
  static const String localAdminPassword = 'password123';
  static const String localJemaatEmail = 'jemaat@example.com';
  static const String localJemaatPassword = 'password123';
  ```
- **Impact**: Jika build production tidak menghilangkan code debug, credentials terekspos
- **Rekomendasi**: Gunakan environment variable atau hapus dari production build. Pastikan code ini hanya ada di debug mode.

#### SEC-02: Google OAuth Placeholder

- **File**: `lib/src/core/environment.dart`
- **Problem**: Google OAuth client ID masih placeholder
  ```dart
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  static const String googleWebClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';
  ```
- **Impact**: Rendah (fitur Google Sign-In belum diimplementasi)
- **Rekomendasi**: Hapus atau konfigurasi saat akan digunakan

#### SEC-03: Docker Credentials dalam docker-compose.yml

- **File**: `docker-compose.yml`
- **Problem**: Database credentials di-hardcode
  ```yaml
  MARIADB_USER: laravel
  MARIADB_PASSWORD: laravel
  MARIADB_ROOT_PASSWORD: root
  ```
- **Impact**: Jika dipakai di production tanpa modifikasi, database terekspos
- **Rekomendasi**: Gunakan `.env` file untuk Docker Compose variables atau Docker secrets

### 🟡 HIGH

#### SEC-04: CORS Terlalu Terbuka

- **File**: `api/config/cors.php`
- **Problem**: CORS mengizinkan semua origin
  ```php
  'allowed_origins' => ['*'],
  'supports_credentials' => false,
  ```
- **Impact**: Semua domain bisa mengakses API
- **Rekomendasi**: Batasi `allowed_origins` ke domain yang diizinkan di production

#### SEC-05: Production ENV File di Repository

- **File**: `api/.env.production`, `api/.env.test`
- **Problem**: File environment production ada di repository
- **Impact**: Credentials production bisa terekspos
- **Rekomendasi**: Tambahkan ke `.gitignore`, gunakan environment management tool

#### SEC-06: SQL Injection via LIKE Clause

- **Problem**: Beberapa controller menggunakan LIKE search tanpa sanitasi wildcard
  ```php
  $q->where('name', 'like', "%{$search}%");
  ```
- **File**: `JemaatManagementController.php`, `KKRegistrationController.php`, `EventController.php`, `NewsController.php`, dll.
- **Impact**: Rendah (parameter binding mencegah injection, tapi `%` dan `_` wildcard tidak di-escape)
- **Rekomendasi**: Escape wildcard characters: `str_replace(['%', '_'], ['\%', '\_'], $search)`

### 🟢 GOOD PRACTICES (Sudah Diimplementasi)

#### Password Hashing

- ✅ BCrypt 12 rounds (`BCRYPT_ROUNDS=12`)
- ✅ Password di-cast sebagai `hashed` di model User

#### Token Authentication

- ✅ Laravel Sanctum token-based authentication
- ✅ Token di-delete saat logout

#### Rate Limiting

- ✅ Throttle middleware pada semua endpoint sensitif
- ✅ Terpisah: `auth-register`, `auth-login`, `api-default`, `api-write`, `broadcast`

#### Sensitive Data Redaction

- ✅ API Activity Logger meredact: `password`, `password_confirmation`, `token`, `access_token`, `fcm_token`
- ✅ Password tersembunyi dari model serialization (`$hidden`)

#### Encrypted Storage

- ✅ Service application attachments menggunakan `encrypted:array` cast

#### Input Validation

- ✅ Form Request validation pada sebagian besar endpoint
- ✅ Dynamic form validation berdasarkan template

#### Trace ID

- ✅ Setiap request mendapat trace ID unik untuk tracking

### 🟡 RECOMMENDATIONS

#### SEC-07: CSRF Protection

- **Status**: Tidak relevan — API murni menggunakan token-based auth (Sanctum), bukan session-based
- **CORS `supports_credentials`**: false — CSRF token tidak diperlukan

#### SEC-08: File Upload Security

- **Status**: File upload ada di event documentation dan news attachments
- **Problem**: Tidak terlihat validasi MIME type yang ketat dan file size per-file
- **Rekomendasi**:
  - Validasi MIME type di Request validation
  - Set max file size per file
  - Scan file untuk malware (opsional)
  - Simpan file di luar web root (sudah via disk `public` + symlink)

#### SEC-09: API Response Leakage

- **Status**: Response body hanya mencatat status, error_code, message, trace_id
- **Rekomendasi**: Pastikan tidak ada stack trace yang ter-expose saat `APP_DEBUG=false`

#### SEC-10: Authorization

- ✅ `can:admin` middleware untuk endpoint admin
- ⚠️ Beberapa controller melakukan authorization check manual (e.g., `ServiceController::exportApplicationCertificate`)
- **Rekomendasi**: Konsistensikan menggunakan Laravel Policy atau Gate

#### SEC-11: Password Reset

- **Status**: Belum ditemukan fitur password reset/forgot password
- **Rekomendasi**: Implementasi password reset flow
