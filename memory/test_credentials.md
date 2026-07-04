# Test credentials (Laravel API + Flutter)

These are seeded by `php artisan db:seed --force` on any environment (SQLite for testing, MariaDB in Docker).

## Users
| Role   | Username         | Email                | Password    |
| ------ | ---------------- | -------------------- | ----------- |
| Admin  | `admin_yehuda`   | `admin@example.com`  | `password123` |
| Jemaat | `jemaat_yehuda`  | `jemaat@example.com` | `password123` |

Both username and email are accepted by `POST /auth/login`. Detection is by presence of `@`.

## KK numbers
| Nomor KK           | Head of family         |
| ------------------ | ---------------------- |
| 5171010000000001   | Admin GPI Yehuda       |
| 5171010000000002   | Jemaat GPI Yehuda      |

## Local run
- API base URL (Flutter web local): `http://localhost:8080/api/v1`
- API base URL (Flutter web preview/prod): `https://api.gereja-gpiyehuda.my.id/api/v1`
- To run tests inside `/app/api`: `php artisan test`

## Push notification credentials (for real FCM v1 delivery)
Not seeded. Provide one of:
- `FCM_CREDENTIALS_JSON=/absolute/path/to/service-account.json`, OR
- `FCM_CREDENTIALS_BASE64=<base64 of service-account.json>`

Plus set `FCM_ENABLED=true`. `FCM_PROJECT_ID` is optional (inferred from JSON).
Without these, the app degrades gracefully: notifications are logged as `queued` with reason `fcm_not_configured`.
