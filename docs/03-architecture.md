# 03 - Architecture

## Arsitektur Project

Aplikasi menggunakan arsitektur **Client-Server** dengan pemisahan jelas antara frontend (Flutter) dan backend (Laravel REST API).

```mermaid
graph TB
    subgraph "Client Layer (Flutter)"
        FL[Flutter App<br/>Dart SDK ^3.10.8]
        FL --> AC[ApiClient<br/>HTTP Client]
        FL --> SC[SessionController<br/>State Management]
        FL --> FM[Firebase Messaging<br/>Push Notifications]
    end

    subgraph "API Gateway"
        NG[Nginx 1.27]
    end

    subgraph "Application Layer (Laravel 13)"
        MW[Middleware Layer<br/>TraceId + ApiActivityLogging + Sanctum + Throttle]
        CT[Controller Layer<br/>15 Controllers]
        SV[Service Layer<br/>4 Services]
        MD[Model Layer<br/>15 Eloquent Models]
        SP[Support Layer<br/>ApiResponse Trait]
    end

    subgraph "Background Processing"
        QW[Queue Worker<br/>database driver]
        JB[Jobs<br/>4 Jobs]
        SD[Scheduler<br/>6 Scheduled Commands]
        CM[Commands<br/>9 Artisan Commands]
    end

    subgraph "Data Layer"
        DB[(MariaDB 11.4)]
        RD[(Redis 7<br/>Cache)]
        FS[File Storage<br/>Public Disk]
    end

    subgraph "External Services"
        FCM[Google FCM v1<br/>Push Notifications]
        SMTP[SMTP / Resend<br/>Email]
    end

    AC --> NG
    NG --> MW
    MW --> CT
    CT --> SV
    CT --> MD
    SV --> MD
    SV --> FCM
    SV --> SMTP
    MD --> DB
    CT --> RD
    QW --> JB
    SD --> CM
    CM --> SV
    JB --> SV
```

## Alur Request

```mermaid
sequenceDiagram
    participant C as Flutter Client
    participant N as Nginx
    participant T as TraceIdMiddleware
    participant A as ApiActivityLogging
    participant S as Sanctum Auth
    participant R as Rate Limiter
    participant CT as Controller
    participant SV as Service
    participant M as Model
    participant DB as MariaDB

    C->>N: HTTP Request
    N->>T: Forward to PHP-FPM
    T->>T: Generate/read X-Trace-Id
    T->>A: Pass with trace_id
    A->>A: Record start time
    A->>S: Pass to Sanctum
    S->>S: Validate token
    S->>R: Check rate limit
    R->>CT: Pass to Controller
    CT->>SV: Call Service (if needed)
    SV->>M: Query Model
    M->>DB: Execute SQL
    DB-->>M: Result
    M-->>SV: Eloquent Collection
    SV-->>CT: Processed Data
    CT-->>A: JSON Response
    A->>A: Log to api_activity_logs (duration_ms, status_code, etc.)
    A-->>T: Response
    T-->>N: Add X-Trace-Id header
    N-->>C: HTTP Response
```

## Alur Response

Semua response API menggunakan format standar melalui `ApiResponse` trait:

### Success Response

```json
{
    "status": "success",
    "message": "Operasi berhasil",
    "data": { ... },
    "trace_id": "req-abc123"
}
```

### Error Response

```json
{
  "status": "error",
  "error_code": "VALIDATION_ERROR",
  "message": "Validasi gagal",
  "trace_id": "req-abc123",
  "errors": {
    "field_name": ["Error message 1"]
  }
}
```

### Paginated Response

```json
{
    "status": "success",
    "message": "...",
    "data": [...],
    "meta": {
        "current_page": 1,
        "per_page": 15,
        "total": 100,
        "last_page": 7,
        "has_more": true
    }
}
```

## Layer Architecture

```mermaid
graph TD
    subgraph "Presentation Layer"
        RT[Routes - api.php]
        MW[Middleware]
    end

    subgraph "Application Layer"
        CT[Controllers<br/>Request handling, validation, response]
        RQ[Form Requests<br/>Validation rules]
        RS[API Resources<br/>Response transformation]
    end

    subgraph "Business Layer"
        SV[Services<br/>PushNotification, FCM, Targeting]
        SP[Support<br/>ApiResponse trait]
    end

    subgraph "Domain Layer"
        MD[Models<br/>Eloquent ORM]
        SC[Scopes & Casts]
    end

    subgraph "Infrastructure Layer"
        DB[(MariaDB)]
        RD[(Redis)]
        FS[File Storage]
        FCM[FCM API]
        EM[Email SMTP]
    end

    RT --> MW --> CT
    CT --> RQ
    CT --> RS
    CT --> SV
    CT --> MD
    SV --> MD
    MD --> DB
    CT --> RD
    SV --> FCM
    SV --> EM
    CT --> FS
```

## MVC Pattern

Project mengikuti pola **MVC + Service Layer**:

| Layer          | Komponen                                  | Tanggung Jawab                             |
| -------------- | ----------------------------------------- | ------------------------------------------ |
| **Model**      | 15 Eloquent Models                        | Representasi data, relasi, casting, scopes |
| **View**       | Flutter App (frontend), Blade views (PDF) | UI rendering                               |
| **Controller** | 15 Controllers                            | Handle HTTP request, validasi, response    |
| **Service**    | 4 Services                                | Business logic kompleks (notifikasi, FCM)  |
| **Support**    | ApiResponse Trait                         | Standarisasi format response               |

## Service Layer

| Service                        | Tanggung Jawab                                                                              |
| ------------------------------ | ------------------------------------------------------------------------------------------- |
| `PushNotificationService`      | Kirim push notification via FCM v1, email fallback, logging ke `notification_dispatch_logs` |
| `FcmAccessTokenProvider`       | Obtain OAuth2 access token dari Google service account, cache 55 menit                      |
| `FcmAuthService`               | Autentikasi FCM (legacy, wrapper)                                                           |
| `NotificationTargetingService` | Resolve target devices berdasarkan type (all/role/users/event_attendees/service_applicants) |

## Event Flow

Belum ditemukan pada source code. Project tidak menggunakan Laravel Events/Listeners. Notifikasi dikirim langsung melalui `PushNotificationService`.

## Broadcast Flow

Belum ditemukan pada source code. Project tidak menggunakan Laravel Broadcasting (WebSocket). Broadcast notifikasi dilakukan melalui REST API endpoint `POST /api/v1/notifications/broadcast`.

## Queue Flow

```mermaid
flowchart LR
    subgraph "Queue Jobs"
        J1[SendEventReminderJob]
        J2[SendKkReminderJob]
        J3[SendServiceFollowUpJob]
        J4[SendAdminDigestJob]
    end

    subgraph "Triggered By"
        C1[SendEventReminderCommand<br/>every 10 min]
        C2[SendKkReminderCommand<br/>daily 09:00]
        C3[SendServiceFollowUpCommand<br/>daily 08:00]
        C4[SendAdminDigestCommand<br/>weekly Mon 08:30]
    end

    subgraph "Queue Driver"
        QD[(Database Queue<br/>jobs table)]
    end

    subgraph "Target"
        NS[PushNotificationService]
        NS --> FCM[FCM v1]
        NS --> EM[Email]
    end

    C1 -->|dispatch| J1
    C2 -->|dispatch| J2
    C3 -->|dispatch| J3
    C4 -->|dispatch| J4
    J1 --> QD
    J2 --> QD
    J3 --> QD
    J4 --> QD
    QD --> NS
```

## Scheduler

| Command                       | Schedule         | Fungsi                            |
| ----------------------------- | ---------------- | --------------------------------- |
| `ArchiveExpiredEventsCommand` | Every 15 min     | Auto-archive event yang expired   |
| `SendEventReminderCommand`    | Every 10 min     | Kirim reminder push H-2           |
| `SendEventLastCallCommand`    | Every 10 min     | Kirim reminder push H-1           |
| `SendServiceFollowUpCommand`  | Daily 08:00      | Follow-up pengajuan layanan stale |
| `SendKkReminderCommand`       | Daily 09:00      | Reminder registrasi KK            |
| `SendAdminDigestCommand`      | Weekly Mon 08:30 | Kirim digest mingguan ke admin    |
