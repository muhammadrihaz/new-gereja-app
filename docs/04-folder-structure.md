# 04 - Folder Structure

## Root Project

```
new-gereja-app/
├── android/              # Flutter Android platform files
├── api/                  # Laravel 13 API backend
├── assets/               # Flutter assets (images, fonts)
├── deploy/               # Deployment scripts
├── docker/               # Docker configuration (Nginx)
├── documents/            # Project documents
├── ios/                  # Flutter iOS platform files
├── lib/                  # Flutter Dart source code (FRONTEND)
├── linux/                # Flutter Linux platform files
├── macos/                # Flutter macOS platform files
├── memory/               # Agent memory files
├── test/                 # Flutter tests
├── web/                  # Flutter Web platform files
├── windows/              # Flutter Windows platform files
├── .dockerignore         # Docker ignore rules
├── .gitignore            # Git ignore rules
├── Dockerfile            # Docker image for PHP-FPM
├── docker-compose.yml    # Docker Compose orchestration
├── firebase.json         # Firebase hosting configuration
├── google-services.json  # Firebase Android configuration
├── pubspec.yaml          # Flutter dependencies
└── run.sh                # Development run script
```

## Backend: `api/` (Laravel 13)

```
api/
├── app/
│   ├── Console/
│   │   ├── Commands/           # 9 Artisan commands
│   │   │   ├── ArchiveExpiredEventsCommand.php
│   │   │   ├── FcmDiagnoseCommand.php
│   │   │   ├── FcmTestSendCommand.php
│   │   │   ├── SendAdminDigestCommand.php
│   │   │   ├── SendEventLastCallCommand.php
│   │   │   ├── SendEventReminderCommand.php
│   │   │   ├── SendKkReminderCommand.php
│   │   │   ├── SendServiceFollowUpCommand.php
│   │   │   └── SendTestEmailCommand.php
│   │   └── Kernel.php          # Console kernel (scheduler legacy)
│   │
│   ├── Http/
│   │   ├── Controllers/        # 15 API controllers
│   │   │   ├── AuthController.php
│   │   │   ├── ChurchProfileController.php
│   │   │   ├── Controller.php
│   │   │   ├── DeviceController.php
│   │   │   ├── EventCategoryController.php
│   │   │   ├── EventController.php
│   │   │   ├── HealthController.php
│   │   │   ├── JemaatManagementController.php
│   │   │   ├── KKRegistrationController.php
│   │   │   ├── NewsController.php
│   │   │   ├── NotificationController.php
│   │   │   ├── ServiceApplicationExportController.php
│   │   │   ├── ServiceController.php
│   │   │   ├── UserController.php
│   │   │   └── VerifyKkController.php
│   │   │
│   │   ├── Middleware/         # 2 custom middleware
│   │   │   ├── ApiActivityLoggingMiddleware.php
│   │   │   └── TraceIdMiddleware.php
│   │   │
│   │   ├── Requests/           # Form request validation (7 folder)
│   │   │   ├── Auth/           # RegisterRequest, LoginRequest, UpdateProfileRequest, UploadProfilePhotoRequest
│   │   │   ├── Church/         # UpsertChurchProfileRequest
│   │   │   ├── Devices/        # RegisterDeviceRequest, RefreshDeviceRequest, RevokeDeviceRequest
│   │   │   ├── Events/         # StoreEventRequest, UploadDocumentationRequest
│   │   │   ├── News/           # StoreNewsRequest, UpdateNewsRequest, UploadNewsAttachmentsRequest
│   │   │   ├── Notifications/  # BroadcastNotificationRequest
│   │   │   └── Services/       # Yg related dengan services
│   │   │
│   │   └── Resources/         # API resource transformers
│   │       ├── EventResource.php
│   │       └── NewsResource.php
│   │
│   ├── Jobs/                   # 4 queued jobs
│   │   ├── SendAdminDigestJob.php
│   │   ├── SendEventReminderJob.php
│   │   ├── SendKkReminderJob.php
│   │   └── SendServiceFollowUpJob.php
│   │
│   ├── Models/                 # 15 Eloquent models
│   │   ├── ApiActivityLog.php
│   │   ├── ChurchProfile.php
│   │   ├── Documentation.php
│   │   ├── Event.php
│   │   ├── EventCategory.php
│   │   ├── EventDocumentation.php
│   │   ├── KKRegistration.php
│   │   ├── News.php
│   │   ├── NewsAttachment.php
│   │   ├── NotificationDispatchLog.php
│   │   ├── ServiceApplication.php
│   │   ├── ServiceCategory.php
│   │   ├── ServiceFormTemplate.php
│   │   ├── User.php
│   │   └── UserDevice.php
│   │
│   ├── Providers/              # Service providers
│   │   └── AppServiceProvider.php
│   │
│   ├── Services/               # 4 business logic services
│   │   ├── FcmAccessTokenProvider.php
│   │   ├── FcmAuthService.php
│   │   ├── NotificationTargetingService.php
│   │   └── PushNotificationService.php
│   │
│   └── Support/                # Reusable traits
│       └── ApiResponse.php
│
├── bootstrap/                  # Laravel bootstrap
├── config/                     # 12 configuration files
│   ├── app.php
│   ├── auth.php
│   ├── cache.php
│   ├── cors.php
│   ├── database.php
│   ├── filesystems.php
│   ├── logging.php
│   ├── mail.php
│   ├── queue.php
│   ├── sanctum.php
│   ├── services.php
│   └── session.php
│
├── database/
│   ├── factories/              # 4 model factories
│   ├── migrations/             # 32 migration files
│   └── seeders/
│       └── DatabaseSeeder.php
│
├── public/                     # Web root (index.php)
├── resources/                  # Blade views, lang, etc.
├── routes/
│   ├── api.php                 # API routes (utama)
│   ├── console.php             # Scheduled tasks
│   └── web.php                 # Web routes (minimal)
├── tests/                      # PHPUnit tests
├── .env.example                # Environment template
├── .env.production             # Production environment
├── .env.test                   # Test environment
├── composer.json               # PHP dependencies
├── package.json                # Node dependencies
├── phpunit.xml                 # Test configuration
└── vite.config.js              # Vite build config
```

## Frontend: `lib/` (Flutter)

```
lib/
├── firebase_options.dart       # Firebase auto-generated config
├── main.dart                   # App entry point, routing, providers
└── src/
    ├── core/                   # Core utilities & state management
    │   ├── api_client.dart         # HTTP client (semua API call)
    │   ├── app_colors.dart         # Color palette
    │   ├── date_format.dart        # Date formatting utilities
    │   ├── device_identity.dart    # Device type detection
    │   ├── environment.dart        # Environment config (local/production)
    │   ├── fcm_bootstrap_service.dart  # FCM token resolver
    │   ├── file_download.dart      # File download abstraction
    │   ├── file_download_io.dart   # File download (mobile)
    │   ├── file_download_web.dart  # File download (web)
    │   ├── models.dart             # Data models (AuthSession, ApiError, PaginatedResult)
    │   ├── notification_badge_controller.dart   # Unread count controller
    │   ├── pwa_install_controller.dart          # PWA install (stub)
    │   ├── pwa_install_controller_stub.dart     # PWA stub impl
    │   ├── pwa_install_controller_web.dart      # PWA web impl
    │   └── session_controller.dart              # Auth session management
    │
    ├── pages/                  # 11 screen pages
    │   ├── admin_dashboard_page.dart        # Admin main dashboard
    │   ├── admin_jemaat_form_page.dart       # Add/edit jemaat form
    │   ├── admin_jemaat_page.dart            # Jemaat management list
    │   ├── admin_kk_management_page.dart     # KK management
    │   ├── admin_profile_page.dart           # Admin profile
    │   ├── home_router_page.dart             # Role-based routing
    │   ├── jemaat_berita_page.dart           # News list & detail
    │   ├── jemaat_dashboard_page.dart        # Jemaat main dashboard
    │   ├── jemaat_edit_profil_page.dart      # Profile edit
    │   ├── jemaat_events_page.dart           # Events list
    │   └── login_page.dart                  # Login & register
    │
    ├── services/               # Firebase services
    │   └── firebase_message_handler.dart     # FCM message handling
    │
    └── widgets/                # 7 reusable widgets
        ├── cached_image.dart               # Network image with cache
        ├── church_logo.dart                # Church logo widget
        ├── empty_state.dart                # Empty state placeholder
        ├── error_state.dart                # Error state display
        ├── google_signin_button.dart       # Google sign-in button
        ├── pwa_install_fab.dart            # PWA install FAB
        └── skeleton_list.dart              # Loading skeleton
```

## Docker: `docker/`

```
docker/
└── nginx/
    └── default.conf            # Nginx config for Laravel
```

## Assets: `assets/`

```
assets/
├── font/
│   └── Poppins/                # Poppins font family (semua weight)
├── image/
│   ├── logo_1.png              # Logo gereja variant 1
│   └── logo_2.png              # Logo gereja variant 2
└── signin-assets/              # Google sign-in button assets
    └── iOS/
        └── png@2x/
            ├── dark/
            └── light/
```
