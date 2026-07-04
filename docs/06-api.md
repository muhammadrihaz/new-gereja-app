# 06 - API Reference

## Base URL

```
/api/v1
```

## Authentication

Menggunakan Laravel Sanctum (Bearer Token). Token dikirim melalui header:

```
Authorization: Bearer {token}
```

## Rate Limiting

| Limiter                  | Digunakan Pada                              |
| ------------------------ | ------------------------------------------- |
| `throttle:auth-register` | POST /auth/register                         |
| `throttle:auth-login`    | POST /auth/login, POST /auth/verify-kk      |
| `throttle:api-default`   | Semua route authenticated                   |
| `throttle:api-write`     | Semua operasi write (POST/PUT/PATCH/DELETE) |
| `throttle:broadcast`     | POST /notifications/broadcast               |

---

## Public Endpoints (No Auth)

### `GET /health`

- **Controller**: `HealthController::__invoke`
- **Middleware**: none
- **Response**: `{ status: "ok", flutter_ready: true, api_version: "v1", features: {...} }`

### `POST /auth/register`

- **Controller**: `AuthController::register`
- **Middleware**: `throttle:auth-register`
- **Body**: `{ username, password, name, nomor_kk, email?, phone_number?, jenis_kelamin?, usia?, alamat?, fcm_token }`
- **Validation**: `RegisterRequest`
- **Logika**: Verifikasi nomor KK + nama terhadap `kk_registrations` dan `users`
- **Success (201)**: `{ token, role, user: {id, username, email} }`
- **Error (422)**: `KK_OR_NAME_NOT_REGISTERED`

### `POST /auth/login`

- **Controller**: `AuthController::login`
- **Middleware**: `throttle:auth-login`
- **Body**: `{ username, password, fcm_token }`
- **Validation**: `LoginRequest`
- **Success (200)**: `{ token, role, user: {id, username, email} }`
- **Error (401)**: `INVALID_CREDENTIALS`

### `POST /auth/verify-kk`

- **Controller**: `VerifyKkController::__invoke`
- **Middleware**: `throttle:auth-login`
- **Body**: `{ name, nomor_kk }`
- **Success (200)**: `{ verified: true, name, nomor_kk }`
- **Error (422)**: `KK_OR_NAME_NOT_REGISTERED`

### `GET /church/profile`

- **Controller**: `ChurchProfileController::show`
- **Middleware**: none
- **Response**: Church profile data (cached 10 min)

---

## Authenticated Endpoints (auth:sanctum)

### Auth / Profile

| Method | URL              | Controller                           | Fungsi                     |
| ------ | ---------------- | ------------------------------------ | -------------------------- |
| GET    | `/auth/me`       | `AuthController::me`                 | Get current user profile   |
| PATCH  | `/auth/me`       | `AuthController::updateProfile`      | Update profile             |
| POST   | `/auth/me/photo` | `AuthController::uploadProfilePhoto` | Upload profile photo       |
| POST   | `/auth/logout`   | `AuthController::logout`             | Logout (revoke all tokens) |

### Devices

| Method | URL                    | Controller                    | Fungsi               |
| ------ | ---------------------- | ----------------------------- | -------------------- |
| GET    | `/devices`             | `DeviceController::index`     | List user's devices  |
| POST   | `/devices/register`    | `DeviceController::register`  | Register FCM device  |
| POST   | `/devices/fcm-refresh` | `DeviceController::refresh`   | Refresh FCM token    |
| DELETE | `/devices/revoke`      | `DeviceController::revoke`    | Revoke single device |
| DELETE | `/devices/revoke-all`  | `DeviceController::revokeAll` | Revoke all devices   |

### Events

| Method | URL                                      | Controller                               | Fungsi                              |
| ------ | ---------------------------------------- | ---------------------------------------- | ----------------------------------- |
| GET    | `/events`                                | `EventController::index`                 | List events (paginated, filterable) |
| GET    | `/events/categories`                     | `EventController::categories`            | List active event categories        |
| GET    | `/events/{event}/documentation/download` | `EventController::downloadDocumentation` | Download docs as ZIP                |

**Query params untuk `/events`**: `status` (upcoming/ongoing/past/archived/active/all), `search`, `category`, `per_page`, `sort_by` (start_at/end_at/created_at/title), `sort_order` (asc/desc)

### News

| Method | URL                                 | Controller                            | Fungsi                      |
| ------ | ----------------------------------- | ------------------------------------- | --------------------------- |
| GET    | `/news`                             | `NewsController::index`               | List news (paginated)       |
| GET    | `/news/{news}`                      | `NewsController::show`                | News detail                 |
| GET    | `/news/{news}/attachments/download` | `NewsController::downloadAttachments` | Download attachments as ZIP |

**Query params**: `per_page`, `search`, `published_only`

### Users

| Method | URL                     | Controller                      | Fungsi                       |
| ------ | ----------------------- | ------------------------------- | ---------------------------- |
| GET    | `/users/family-members` | `UserController::familyMembers` | Get family members (same KK) |

### Services

| Method | URL                                                    | Controller                                                     | Fungsi                         |
| ------ | ------------------------------------------------------ | -------------------------------------------------------------- | ------------------------------ |
| GET    | `/services/categories`                                 | `ServiceController::categories`                                | List active service categories |
| GET    | `/services/applications`                               | `ServiceController::applications`                              | List user's applications       |
| GET    | `/services/applications/export/csv`                    | `ServiceApplicationExportController::exportAllApplicationsCsv` | Export to CSV                  |
| GET    | `/services/forms`                                      | `ServiceController::templates`                                 | List all form templates        |
| GET    | `/services/forms/{category}`                           | `ServiceController::showTemplate`                              | Get template by category       |
| POST   | `/services/apply`                                      | `ServiceController::apply`                                     | Submit service application     |
| GET    | `/services/applications/{application}/certificate/pdf` | `ServiceController::exportApplicationCertificate`              | Download certificate PDF       |

### Notifications

| Method | URL                           | Controller                            | Fungsi                    |
| ------ | ----------------------------- | ------------------------------------- | ------------------------- |
| GET    | `/notifications/inbox`        | `NotificationController::inbox`       | User's notification inbox |
| GET    | `/notifications/unread-count` | `NotificationController::unreadCount` | Unread notification count |
| PATCH  | `/notifications/{log}/read`   | `NotificationController::markRead`    | Mark notification as read |
| PATCH  | `/notifications/read-all`     | `NotificationController::markAllRead` | Mark all as read          |

---

## Admin-Only Endpoints (auth:sanctum + can:admin)

### Users / Jemaat

| Method | URL                 | Controller                            | Fungsi                      |
| ------ | ------------------- | ------------------------------------- | --------------------------- |
| GET    | `/users`            | `UserController::index`               | List all users              |
| GET    | `/users/families`   | `UserController::families`            | List families grouped by KK |
| GET    | `/jemaats`          | `JemaatManagementController::index`   | List jemaat (filterable)    |
| POST   | `/jemaats`          | `JemaatManagementController::store`   | Create jemaat               |
| GET    | `/jemaats/{jemaat}` | `JemaatManagementController::show`    | Jemaat detail + family      |
| PUT    | `/jemaats/{jemaat}` | `JemaatManagementController::update`  | Update jemaat               |
| DELETE | `/jemaats/{jemaat}` | `JemaatManagementController::destroy` | Delete jemaat               |

### KK Registration

| Method | URL                      | Controller                          | Fungsi                |
| ------ | ------------------------ | ----------------------------------- | --------------------- |
| GET    | `/kk-registrations`      | `KKRegistrationController::index`   | List KK registrations |
| POST   | `/kk-registrations`      | `KKRegistrationController::store`   | Create KK             |
| GET    | `/kk-registrations/{kk}` | `KKRegistrationController::show`    | KK detail + members   |
| PUT    | `/kk-registrations/{kk}` | `KKRegistrationController::update`  | Update KK             |
| DELETE | `/kk-registrations/{kk}` | `KKRegistrationController::destroy` | Delete KK             |

### News (Admin)

| Method | URL                        | Controller                          | Fungsi                    |
| ------ | -------------------------- | ----------------------------------- | ------------------------- |
| POST   | `/news`                    | `NewsController::store`             | Create news               |
| PUT    | `/news/{news}`             | `NewsController::update`            | Update news               |
| DELETE | `/news/{news}`             | `NewsController::destroy`           | Delete news + attachments |
| POST   | `/news/{news}/attachments` | `NewsController::uploadAttachments` | Upload attachments        |

### Events (Admin)

| Method | URL                             | Controller                             | Fungsi                       |
| ------ | ------------------------------- | -------------------------------------- | ---------------------------- |
| POST   | `/events`                       | `EventController::store`               | Create event                 |
| PUT    | `/events/{event}`               | `EventController::update`              | Update event                 |
| POST   | `/events/{event}/documentation` | `EventController::uploadDocumentation` | Upload doc files (max 200MB) |

### Event Categories (Admin)

| Method | URL                             | Controller                         | Fungsi          |
| ------ | ------------------------------- | ---------------------------------- | --------------- |
| POST   | `/events/categories`            | `EventCategoryController::store`   | Create category |
| PUT    | `/events/categories/{category}` | `EventCategoryController::update`  | Update category |
| DELETE | `/events/categories/{category}` | `EventCategoryController::destroy` | Delete category |

### Service Management (Admin)

| Method | URL                                           | Controller                             | Fungsi                    |
| ------ | --------------------------------------------- | -------------------------------------- | ------------------------- |
| POST   | `/services/forms`                             | `ServiceController::upsertTemplate`    | Create form template      |
| PUT    | `/services/forms/{category}`                  | `ServiceController::upsertTemplate`    | Update form template      |
| DELETE | `/services/forms/{category}`                  | `ServiceController::destroyTemplate`   | Delete form template      |
| PATCH  | `/services/applications/{application}`        | `ServiceController::updateApplication` | Update application        |
| PATCH  | `/services/applications/{application}/status` | `ServiceController::updateStatus`      | Update application status |

### Church Profile (Admin)

| Method | URL               | Controller                        | Fungsi                |
| ------ | ----------------- | --------------------------------- | --------------------- |
| PUT    | `/church/profile` | `ChurchProfileController::upsert` | Update church profile |

### Broadcast (Admin)

| Method | URL                        | Controller                          | Fungsi                      |
| ------ | -------------------------- | ----------------------------------- | --------------------------- |
| POST   | `/notifications/broadcast` | `NotificationController::broadcast` | Broadcast push notification |

**Body**: `{ title, message, target_type: "all"/"role"/"users"/"event_attendees"/"service_applicants", target_filters: {} }`
