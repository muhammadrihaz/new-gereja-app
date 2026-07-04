# PRD — GPI Yehuda Church Management App

Original problem: Full production stabilization and UI modernization of a Flutter + Laravel church management system covering members, events, news, gallery, service requests, dashboards, push notifications, performance, and responsive layouts.

## Roles
- **Church Staff / Admin**: manage members, events, news, gallery, service requests, notifications, dashboards.
- **Church Member (Jemaat)**: view events (active/upcoming only), read news, submit service requests, download gallery, receive notifications.

## Tech stack
- Flutter 3.44 (Android, iOS, Web, Desktop).
- Laravel 13 (PHP 8.4), SQLite/MariaDB, Sanctum auth.
- Firebase Cloud Messaging (HTTP v1 API — migrated from deprecated Legacy API).

## Static core requirements
- Events auto-archive after end time; archived only visible to Church Staff.
- News list must display cover, title, date, relative time, excerpt. Detail: hero image, content, gallery, downloadable gallery.
- Gallery: grid, preview, zoom, swipe, download, lazy load, cache.
- Service Requests: dynamic forms per category, validated, backward compatible.
- Responsive: mobile bottom nav, tablet rail, desktop sidebar. No fixed sizes.
- Consistent Bahasa Indonesia UI; English only in code/logs/docs.

---

## Progress log

### Checkpoint 1.A — Backend & API audit (COMPLETED 2026-07-02)
- Fixed SQLite-hostile migration `2026_07_01_000004_make_events_date_nullable.php` (was skipped on sqlite so seeder failed).
- Added additive migration `2026_07_02_000001_add_archive_fields_to_events_table.php` with `is_archived` + `archived_at` + indexes on `start_at`, `end_at`, `is_archived`.
- Extended `Event` model with archive fields, scope, expiry helper.
- Rewrote `EventController` with proper archive filtering, status filter (`upcoming|ongoing|past|archived|active|all`), search, category filter, sort options, pagination meta with `has_more`, and correctly resolved storage path for `downloadDocumentation` across public/private/legacy disks. Members are automatically prevented from seeing archived events; admins can filter to archive.
- Added `ArchiveExpiredEventsCommand` (`events:archive-expired`), scheduled every 15 minutes.
- Rewrote `EventResource` to include `is_archived`, `archived_at`, `is_expired`, `documentation_count`, and (when loaded) full documentation URLs.
- Rewrote `NewsResource`: adds `excerpt`, normalized `cover_image`, `attachments` array with public URLs & `is_image`, and omits heavy `content` in list mode.
- Rewrote `NewsController`: search filter, `published_only` filter, storage on `public` disk with URL resolution, cleaner delete (drops orphan files), proper zip download path resolution.
- Rewrote `PushNotificationService` to use **FCM HTTP v1 API** (Google service-account OAuth2) — Google shut down the legacy `fcm.googleapis.com/fcm/send` API on 2024-06-20 (root cause of failing production push). Legacy path kept only as fallback when v1 not configured. Auto-invalidates dead tokens (`UNREGISTERED`, `INVALID_ARGUMENT`, etc.).
- Added `FcmAccessTokenProvider` service (uses `google/auth` package, tokens cached 55min).
- Extended `config/services.php` with `credentials_json`, `credentials_base64`, `project_id` for FCM v1.
- Updated `ServiceController::applications` with `search`, `category`, `status` filters + pagination meta.
- Updated Flutter `ApiClient` with `PaginatedResult<T>`, `eventsPaginated`, `newsPaginated`, `newsDetail`, `serviceApplicationsPaginated`, and full validation error parsing on `ApiError` (with `isValidationError`, `isAuthError`, `isForbidden`, `isServerError` helpers).
- Extended `ApiError` to carry field-level `errors` map.
- Added feature tests: archive visibility (2 roles), archive command, search filters, pagination meta, news attachments detail, news content omission in list, unpublished hiding. **All 67 tests passing (up from 57).**
- `flutter analyze`: no issues.

### Checkpoint 1.B — Flutter modernization + Notification badge (COMPLETED 2026-07-02)

Backend additions:
- Migration `2026_07_02_000002_add_read_at_to_notification_dispatch_logs_table.php` — additive `read_at` + composite indexes.
- `NotificationDispatchLog` model gains `read_at` cast.
- `NotificationController`: added `inbox`, `unreadCount`, `markRead`, `markAllRead` endpoints. Email dispatch rows are excluded. Route model binding enforces per-user ownership.
- Routes `GET /notifications/inbox`, `GET /notifications/unread-count`, `PATCH /notifications/{log}/read`, `PATCH /notifications/read-all`.
- New tests file `tests/Feature/Notifications/NotificationInboxTest.php` — **6 new tests**. Total tests: **73** (up from 67).

Flutter additions:
- Packages: `cached_network_image`, `shimmer`, `timeago` (Indonesian locale).
- Widgets `lib/src/widgets/skeleton_list.dart` (`SkeletonList` + `SkeletonGrid`), `error_state.dart` (`ErrorStateView` — ApiError-aware icons, retry button), `empty_state.dart` (`EmptyStateView`), `cached_image.dart` (`CachedImage` with shimmer placeholder + fallback icon).
- `NotificationBadgeController` (`lib/src/core/notification_badge_controller.dart`) — 60s polling, silent failures, `refresh()`, `clearLocally()`, `decrement()`, auto pause on logout.
- Wired through `main.dart` → `HomeRouterPage` → `JemaatDashboardPage`; token sync via session listener.
- Badge on Jemaat Bottom Nav "Beranda" tab (`_BadgeIcon` using Material 3 `Badge`).
- Rewrote `JemaatBeritaPage`: server-side search + pagination via `newsPaginated`, infinite scroll, 1/2/3-column adaptive grid, cover with `CachedImage`, `timeago` relative time + absolute fallback, skeleton loader, error state, empty state, pull-to-refresh. Detail page `JemaatBeritaDetailPage` with hero cover, full content, tappable image gallery (`_GalleryGrid` + full-screen `_GalleryViewer` with pinch-to-zoom via `InteractiveViewer` and swipe via `PageView`), non-image attachments list, unified "Unduh Galeri & Lampiran" button.
- New `JemaatEventsPage`: `eventsPaginated` with `status=active`; **admin-only** "Aktif / Arsip" tab bar (`TabBar` with 2 tabs; jemaat sees only 1). Modern event card with date badge (day + month), category chip, archived/expired chip, location & duration.
- Retry + timeout policy in `ApiClient._send`: 15s timeout, exponential backoff (250ms → 2s) with 2 retries for network errors + idempotent 502/503/504.
- Wired new methods `notificationInbox`, `notificationUnreadCount`, `markNotificationRead`, `markAllNotificationsRead`, plus migrated `eventsPaginated`, `newsPaginated`, `newsDetail` to use `_send`.
- Jemaat dashboard tab "Event" now renders `JemaatEventsPage` (legacy inline events widget kept as dead code for reference, tagged `_legacyTabEvent`).

Verification:
- `php artisan test` → **73 passed / 216 assertions**.
- `flutter analyze` → No issues.
- `flutter build web --release` → Build successful (`build/web/` populated).

### Files touched (Checkpoint 1.B)
Backend:
- `api/database/migrations/2026_07_02_000002_add_read_at_to_notification_dispatch_logs_table.php` (NEW)
- `api/app/Models/NotificationDispatchLog.php`
- `api/app/Http/Controllers/NotificationController.php`
- `api/routes/api.php`
- `api/tests/Feature/Notifications/NotificationInboxTest.php` (NEW)

Frontend:
- `lib/main.dart`
- `lib/pubspec.yaml` — added `cached_network_image`, `shimmer`, `timeago`
- `lib/src/core/api_client.dart` — retry/timeout, notification endpoints
- `lib/src/core/notification_badge_controller.dart` (NEW)
- `lib/src/pages/home_router_page.dart`
- `lib/src/pages/jemaat_dashboard_page.dart` — badge, uses `JemaatEventsPage`
- `lib/src/pages/jemaat_berita_page.dart` — full rewrite
- `lib/src/pages/jemaat_events_page.dart` (NEW)
- `lib/src/widgets/cached_image.dart` (NEW)
- `lib/src/widgets/empty_state.dart` (NEW)
- `lib/src/widgets/error_state.dart` (NEW)
- `lib/src/widgets/skeleton_list.dart` (NEW)

### Next
- **Checkpoint 2**: Push notifications end-to-end audit (Flutter FCM token refresh + background message handler + wire deep-link navigation; Laravel v1 delivery verification). Requires Firebase service-account JSON from user.
- **Checkpoint 3**: Notification inbox page (jemaat can list inbox, mark read, tap → deep-link into news/event) + admin dashboard skeleton/error/empty rollout.
- **Checkpoint 4**: Gallery module (news detail already uses gallery; extract to reusable module; add Pinterest grid).
- **Checkpoint 5**: Service Requests dynamic form step-by-step UX.
- **Checkpoint 6**: Dashboard redesigns.
- **Checkpoint 7**: Responsive audit + performance validation.

---

## Files touched (Checkpoint 1.A)
### Backend
- `api/database/migrations/2026_07_01_000004_make_events_date_nullable.php` — cross-driver
- `api/database/migrations/2026_07_02_000001_add_archive_fields_to_events_table.php` — NEW
- `api/app/Models/Event.php`
- `api/app/Http/Resources/EventResource.php`
- `api/app/Http/Resources/NewsResource.php`
- `api/app/Http/Controllers/EventController.php`
- `api/app/Http/Controllers/NewsController.php`
- `api/app/Http/Controllers/ServiceController.php`
- `api/app/Console/Kernel.php`
- `api/app/Console/Commands/ArchiveExpiredEventsCommand.php` — NEW
- `api/app/Services/PushNotificationService.php` — full v1 rewrite
- `api/app/Services/FcmAccessTokenProvider.php` — NEW
- `api/config/services.php`
- `api/composer.json` / `composer.lock` — added `google/auth`
- `api/tests/Feature/Events/EventApiTest.php` — 6 new tests
- `api/tests/Feature/News/NewsApiTest.php` — 4 new tests

### Frontend (Flutter)
- `lib/src/core/models.dart` — `ApiError.errors` + `PaginatedResult<T>`
- `lib/src/core/api_client.dart` — validation error parsing, `eventsPaginated`, `newsPaginated`, `newsDetail`, `serviceApplicationsPaginated`
