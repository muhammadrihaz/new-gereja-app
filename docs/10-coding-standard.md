# 10 - Coding Standard

## Naming Convention

### PHP (Laravel Backend)

| Elemen          | Konvensi                           | Contoh                                        |
| --------------- | ---------------------------------- | --------------------------------------------- |
| Controller      | PascalCase + `Controller` suffix   | `EventController`, `KKRegistrationController` |
| Model           | PascalCase, singular               | `User`, `Event`, `KKRegistration`             |
| Migration       | snake_case dengan prefix timestamp | `2026_03_26_000002_create_events_table.php`   |
| Service         | PascalCase + `Service` suffix      | `PushNotificationService`                     |
| Middleware      | PascalCase + `Middleware` suffix   | `ApiActivityLoggingMiddleware`                |
| Job             | PascalCase + `Job` suffix          | `SendEventReminderJob`                        |
| Command         | PascalCase + `Command` suffix      | `ArchiveExpiredEventsCommand`                 |
| Request         | PascalCase + `Request` suffix      | `StoreEventRequest`                           |
| Resource        | PascalCase + `Resource` suffix     | `EventResource`                               |
| Trait           | PascalCase                         | `ApiResponse`                                 |
| Database table  | snake_case, plural                 | `service_applications`                        |
| Database column | snake_case                         | `created_by`, `nomor_kk`                      |
| Route prefix    | kebab-case                         | `kk-registrations`, `family-members`          |
| Config keys     | snake_case                         | `services.fcm.enabled`                        |

### Dart (Flutter Frontend)

| Elemen          | Konvensi                                   | Contoh                           |
| --------------- | ------------------------------------------ | -------------------------------- |
| File            | snake_case                                 | `admin_dashboard_page.dart`      |
| Class           | PascalCase                                 | `SessionController`, `ApiClient` |
| Method/Function | camelCase                                  | `signIn()`, `fetchEvents()`      |
| Variable        | camelCase                                  | `isAuthenticated`, `fcmToken`    |
| Constant        | camelCase (dengan `static const`)          | `localAdminEmail`                |
| Enum            | PascalCase (enum name), camelCase (values) | `UserRole.admin`                 |
| Widget          | PascalCase                                 | `CachedImage`, `SkeletonList`    |
| Page            | PascalCase + `Page` suffix                 | `AdminDashboardPage`             |

## Struktur Controller

Semua controller mengikuti pola:

```php
class ExampleController extends Controller
{
    use ApiResponse;  // WAJIB: standardized response

    // Optional: Constructor injection untuk services
    public function __construct(private readonly SomeService $service) {}

    // Method menggunakan Form Request untuk validasi
    public function store(StoreExampleRequest $request): JsonResponse
    {
        // 1. Get authenticated user
        $user = auth('sanctum')->user();

        // 2. Business logic (langsung atau via service)
        $result = Model::query()->create([...]);

        // 3. Return standardized response
        return $this->successResponse($result, 'Pesan berhasil', 201);
    }
}
```

### Pola yang Diikuti:

- Selalu return `JsonResponse`
- Selalu gunakan `$this->successResponse()` atau `$this->errorResponse()`
- Auth via `auth('sanctum')->user()` atau `auth('sanctum')->id()`
- Validasi menggunakan Form Request classes (bukan inline `$request->validate()`) untuk operasi CRUD utama
- Beberapa controller menggunakan inline validation untuk operasi sederhana (e.g., `JemaatManagementController::store`)

## Struktur Service

```php
class ExampleService
{
    // Constructor injection
    public function __construct(
        private readonly DependencyService $dependency
    ) {}

    // Public methods = business logic entry points
    public function doSomething(array $params): ResultType
    {
        // Business logic
    }

    // Private methods = internal helpers
    private function helperMethod(): void {}
}
```

## Penggunaan Helper

- **`ApiResponse` Trait**: Digunakan di SEMUA controller untuk standarisasi response
- **`AuthController::normalizeName()`**: Static method untuk normalisasi nama (dipakai juga di `VerifyKkController`)
- **Tidak ada folder `Helpers`**: Helper functions inline atau via static methods

## Penggunaan Trait

| Trait          | Digunakan Di     | Fungsi                                 |
| -------------- | ---------------- | -------------------------------------- |
| `ApiResponse`  | Semua Controller | `successResponse()`, `errorResponse()` |
| `HasApiTokens` | User Model       | Sanctum token management               |
| `HasFactory`   | Semua Model      | Factory support                        |
| `Notifiable`   | User Model       | Laravel notifications                  |

## Penggunaan Event

Belum ditemukan pada source code. Project **tidak** menggunakan Laravel Events/Listeners.

## Penggunaan DTO

Belum ditemukan pada source code. Project **tidak** menggunakan DTO (Data Transfer Objects). Data diteruskan sebagai array.

## Penggunaan Request Validation

Request validation diorganisir per domain:

```
app/Http/Requests/
├── Auth/
│   ├── RegisterRequest.php
│   ├── LoginRequest.php
│   ├── UpdateProfileRequest.php
│   └── UploadProfilePhotoRequest.php
├── Church/
│   └── UpsertChurchProfileRequest.php
├── Devices/
│   ├── RegisterDeviceRequest.php
│   ├── RefreshDeviceRequest.php
│   └── RevokeDeviceRequest.php
├── Events/
│   ├── StoreEventRequest.php
│   └── UploadDocumentationRequest.php
├── News/
│   ├── StoreNewsRequest.php
│   ├── UpdateNewsRequest.php
│   └── UploadNewsAttachmentsRequest.php
├── Notifications/
│   └── BroadcastNotificationRequest.php
└── Services/
    ├── ApplyServiceRequest.php
    ├── UpdateServiceApplicationRequest.php
    ├── UpsertServiceFormTemplateRequest.php
    └── UpdateServiceStatusRequest.php
```

## API Response Format

Semua response selalu mengikuti format:

```json
// Success
{
    "status": "success",
    "message": "...",
    "data": "...",
    "trace_id": "req-..."
}

// Error
{
    "status": "error",
    "error_code": "...",
    "message": "...",
    "trace_id": "req-...",
    "errors": {}  // optional
}
```

## Bahasa Response

- Semua response message dan error message menggunakan **Bahasa Indonesia**
- Contoh: "Registrasi berhasil", "Username atau password salah", "Jemaat berhasil ditambahkan"

## Code Style

- PHP 8.3+ features: readonly properties, named arguments, match expressions, first-class callables
- Strict return types pada semua method
- `void` return type untuk methods tanpa return
- `?` nullable types
- Consistent spacing dan formatting (Laravel Pint)
- Closure return type hints: `fn($x) => ...`
