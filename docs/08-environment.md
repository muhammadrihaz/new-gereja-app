# 08 - Environment Variables

## Laravel API (`api/.env`)

### Application

| Variable                 | Fungsi             | Contoh                   | Wajib | Default            |
| ------------------------ | ------------------ | ------------------------ | ----- | ------------------ |
| `APP_NAME`               | Nama aplikasi      | `GerejaApp`              | Ya    | `Laravel`          |
| `APP_ENV`                | Environment        | `local` / `production`   | Ya    | `local`            |
| `APP_KEY`                | Encryption key     | `base64:xxxxx`           | Ya    | -                  |
| `APP_DEBUG`              | Debug mode         | `true` / `false`         | Ya    | `true`             |
| `APP_URL`                | Base URL API       | `https://api.gereja.com` | Ya    | `http://localhost` |
| `APP_LOCALE`             | Default locale     | `en`                     | Tidak | `en`               |
| `APP_FALLBACK_LOCALE`    | Fallback locale    | `en`                     | Tidak | `en`               |
| `APP_FAKER_LOCALE`       | Faker locale       | `en_US`                  | Tidak | `en_US`            |
| `APP_MAINTENANCE_DRIVER` | Maintenance driver | `file`                   | Tidak | `file`             |

### Security

| Variable        | Fungsi                  | Contoh | Wajib | Default |
| --------------- | ----------------------- | ------ | ----- | ------- |
| `BCRYPT_ROUNDS` | Password hashing rounds | `12`   | Tidak | `12`    |

### Logging

| Variable                   | Fungsi                  | Contoh   | Wajib | Default  |
| -------------------------- | ----------------------- | -------- | ----- | -------- |
| `LOG_CHANNEL`              | Log channel             | `stack`  | Tidak | `stack`  |
| `LOG_STACK`                | Stack channels          | `single` | Tidak | `single` |
| `LOG_DEPRECATIONS_CHANNEL` | Deprecation log channel | `null`   | Tidak | `null`   |
| `LOG_LEVEL`                | Minimum log level       | `debug`  | Tidak | `debug`  |

### Database

| Variable        | Fungsi            | Contoh                      | Wajib | Default     |
| --------------- | ----------------- | --------------------------- | ----- | ----------- |
| `DB_CONNECTION` | Database driver   | `mysql`                     | Ya    | `mysql`     |
| `DB_HOST`       | Database host     | `127.0.0.1` / `db` (Docker) | Ya    | `127.0.0.1` |
| `DB_PORT`       | Database port     | `3306`                      | Tidak | `3306`      |
| `DB_DATABASE`   | Database name     | `api`                       | Ya    | `api`       |
| `DB_USERNAME`   | Database user     | `root` / `laravel`          | Ya    | `root`      |
| `DB_PASSWORD`   | Database password | `secret`                    | Ya    | ``          |

### Session

| Variable           | Fungsi                   | Contoh     | Wajib | Default    |
| ------------------ | ------------------------ | ---------- | ----- | ---------- |
| `SESSION_DRIVER`   | Session driver           | `database` | Tidak | `database` |
| `SESSION_LIFETIME` | Session lifetime (menit) | `120`      | Tidak | `120`      |
| `SESSION_ENCRYPT`  | Encrypt session          | `false`    | Tidak | `false`    |
| `SESSION_PATH`     | Cookie path              | `/`        | Tidak | `/`        |
| `SESSION_DOMAIN`   | Cookie domain            | `null`     | Tidak | `null`     |

### Cache & Queue

| Variable               | Fungsi             | Contoh               | Wajib | Default    |
| ---------------------- | ------------------ | -------------------- | ----- | ---------- |
| `BROADCAST_CONNECTION` | Broadcast driver   | `log`                | Tidak | `log`      |
| `FILESYSTEM_DISK`      | Default filesystem | `local`              | Tidak | `local`    |
| `QUEUE_CONNECTION`     | Queue driver       | `database` / `redis` | Ya    | `database` |
| `CACHE_STORE`          | Cache store        | `database` / `redis` | Tidak | `database` |

### Redis

| Variable         | Fungsi               | Contoh                | Wajib | Default     |
| ---------------- | -------------------- | --------------------- | ----- | ----------- |
| `REDIS_CLIENT`   | Redis client library | `phpredis` / `predis` | Tidak | `phpredis`  |
| `REDIS_HOST`     | Redis host           | `127.0.0.1` / `redis` | Tidak | `127.0.0.1` |
| `REDIS_PASSWORD` | Redis password       | `null`                | Tidak | `null`      |
| `REDIS_PORT`     | Redis port           | `6379`                | Tidak | `6379`      |

### Mail

| Variable            | Fungsi        | Contoh                    | Wajib     | Default             |
| ------------------- | ------------- | ------------------------- | --------- | ------------------- |
| `MAIL_MAILER`       | Mail driver   | `smtp` / `resend` / `log` | Tidak     | `log`               |
| `MAIL_SCHEME`       | Mail scheme   | `null`                    | Tidak     | `null`              |
| `MAIL_HOST`         | SMTP host     | `smtp.resend.com`         | Jika SMTP | `127.0.0.1`         |
| `MAIL_PORT`         | SMTP port     | `587` / `2525`            | Jika SMTP | `2525`              |
| `MAIL_USERNAME`     | SMTP username | `resend`                  | Jika SMTP | `null`              |
| `MAIL_PASSWORD`     | SMTP password | `re_xxxxx`                | Jika SMTP | `null`              |
| `MAIL_FROM_ADDRESS` | Sender email  | `noreply@gereja.com`      | Ya        | `hello@example.com` |
| `MAIL_FROM_NAME`    | Sender name   | `Gereja App`              | Tidak     | `${APP_NAME}`       |

### FCM (Firebase Cloud Messaging)

| Variable                      | Fungsi                         | Contoh                              | Wajib       | Default                               |
| ----------------------------- | ------------------------------ | ----------------------------------- | ----------- | ------------------------------------- |
| `FCM_ENABLED`                 | Enable FCM push                | `true` / `false`                    | Ya          | `false`                               |
| `FCM_SERVER_KEY`              | Legacy server key (deprecated) | `AAAA...`                           | Tidak       | -                                     |
| `FCM_PROJECT_ID`              | Firebase project ID            | `my-project-id`                     | Jika FCM    | -                                     |
| `FCM_ENDPOINT`                | Legacy FCM endpoint            | URL                                 | Tidak       | `https://fcm.googleapis.com/fcm/send` |
| `FCM_CREDENTIALS_JSON`        | Path ke service account JSON   | `/path/to/sa.json`                  | Jika FCM v1 | -                                     |
| `FCM_CREDENTIALS_BASE64`      | Base64 service account JSON    | `eyJ...`                            | Alternatif  | -                                     |
| `FCM_SERVICE_ACCOUNT_PATH`    | Path internal                  | `app/firebase-service-account.json` | Tidak       | `app/firebase-service-account.json`   |
| `EMAIL_NOTIFICATIONS_ENABLED` | Enable email notifications     | `true` / `false`                    | Tidak       | `false`                               |

### AWS (jika digunakan)

| Variable                | Fungsi     | Contoh      | Wajib | Default     |
| ----------------------- | ---------- | ----------- | ----- | ----------- |
| `AWS_ACCESS_KEY_ID`     | AWS key    | -           | Tidak | -           |
| `AWS_SECRET_ACCESS_KEY` | AWS secret | -           | Tidak | -           |
| `AWS_DEFAULT_REGION`    | AWS region | `us-east-1` | Tidak | `us-east-1` |
| `AWS_BUCKET`            | S3 bucket  | -           | Tidak | -           |

### Vite

| Variable        | Fungsi            | Contoh      | Wajib | Default       |
| --------------- | ----------------- | ----------- | ----- | ------------- |
| `VITE_APP_NAME` | Frontend app name | `GerejaApp` | Tidak | `${APP_NAME}` |

## Flutter (`lib/src/core/environment.dart`)

| Constant              | Fungsi                       | Value                                     |
| --------------------- | ---------------------------- | ----------------------------------------- |
| `localAdminEmail`     | Dev autofill admin email     | `admin@example.com`                       |
| `localAdminPassword`  | Dev autofill admin password  | `password123`                             |
| `localJemaatEmail`    | Dev autofill jemaat email    | `jemaat@example.com`                      |
| `localJemaatPassword` | Dev autofill jemaat password | `password123`                             |
| `googleClientId`      | Google OAuth client ID       | `YOUR_GOOGLE_CLIENT_ID` (placeholder)     |
| `googleWebClientId`   | Google OAuth web client ID   | `YOUR_GOOGLE_WEB_CLIENT_ID` (placeholder) |

> **Note**: Environment detection di Flutter berdasarkan `kDebugMode` — debug = local, release = production.
