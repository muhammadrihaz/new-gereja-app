<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\ForgotPasswordController;
use App\Http\Controllers\DeviceController;
use App\Http\Controllers\EventCategoryController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\HealthController;
use App\Http\Controllers\JemaatManagementController;
use App\Http\Controllers\KKRegistrationController;
use App\Http\Controllers\NewsController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\ChurchProfileController;
use App\Http\Controllers\ServiceApplicationExportController;
use App\Http\Controllers\ServiceController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\VerifyKkController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', HealthController::class);

    Route::post('/auth/register', [AuthController::class, 'register'])->middleware('throttle:auth-register');
    Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:auth-login');
    Route::post('/forgot-password/verify', [ForgotPasswordController::class, 'verify'])->middleware('throttle:auth-login');
    Route::post('/forgot-password/reset', [ForgotPasswordController::class, 'reset'])->middleware('throttle:auth-login');
    Route::post('/auth/google-signin', [\App\Http\Controllers\GoogleAuthController::class, 'signIn'])->middleware('throttle:auth-login');
    Route::post('/auth/verify-kk', VerifyKkController::class)->middleware('throttle:auth-login');
    Route::get('/church/profile', [ChurchProfileController::class, 'show']);

    Route::middleware(['auth:sanctum', 'throttle:api-default'])->group(function (): void {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::patch('/auth/me', [AuthController::class, 'updateProfile'])->middleware('throttle:api-write');
        Route::post('/auth/me/photo', [AuthController::class, 'uploadProfilePhoto'])->middleware('throttle:api-write');
        Route::post('/auth/logout', [AuthController::class, 'logout'])->middleware('throttle:api-write');

        Route::get('/devices', [DeviceController::class, 'index']);
        Route::post('/devices/register', [DeviceController::class, 'register'])->middleware('throttle:api-write');
        Route::post('/devices/fcm-refresh', [DeviceController::class, 'refresh'])->middleware('throttle:api-write');
        Route::delete('/devices/revoke', [DeviceController::class, 'revoke'])->middleware('throttle:api-write');
        Route::delete('/devices/revoke-all', [DeviceController::class, 'revokeAll'])->middleware('throttle:api-write');

        Route::get('/events', [EventController::class, 'index']);
        Route::get('/events/categories', [EventController::class, 'categories']);
        Route::get('/events/{event}/documentation/download', [EventController::class, 'downloadDocumentation']);

        Route::get('/news', [NewsController::class, 'index']);
        Route::get('/news/{news}', [NewsController::class, 'show']);
        Route::get('/news/{news}/attachments/download', [NewsController::class, 'downloadAttachments']);

        Route::get('/users/family-members', [UserController::class, 'familyMembers']);

        Route::get('/services/categories', [ServiceController::class, 'categories']);
        Route::get('/services/applications', [ServiceController::class, 'applications']);
        Route::get('/services/applications/export/csv', [ServiceApplicationExportController::class, 'exportAllApplicationsCsv']);
        Route::get('/services/forms', [ServiceController::class, 'templates']);
        Route::get('/services/forms/{category}', [ServiceController::class, 'showTemplate']);
        Route::post('/services/apply', [ServiceController::class, 'apply'])->middleware('throttle:api-write');
        Route::get('/services/applications/{application}/certificate/pdf', [ServiceController::class, 'exportApplicationCertificate']);

        // Personal notification inbox + unread badge for all authenticated users.
        Route::get('/notifications/inbox', [NotificationController::class, 'inbox']);
        Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
        Route::patch('/notifications/{log}/read', [NotificationController::class, 'markRead'])->middleware('throttle:api-write');
        Route::patch('/notifications/read-all', [NotificationController::class, 'markAllRead'])->middleware('throttle:api-write');

        Route::middleware('can:admin')->group(function (): void {
            Route::get('/users', [UserController::class, 'index']);
            Route::get('/users/families', [UserController::class, 'families']);
            Route::get('/jemaats', [JemaatManagementController::class, 'index']);
            Route::post('/jemaats', [JemaatManagementController::class, 'store'])->middleware('throttle:api-write');
            Route::get('/jemaats/{jemaat}', [JemaatManagementController::class, 'show']);
            Route::put('/jemaats/{jemaat}', [JemaatManagementController::class, 'update'])->middleware('throttle:api-write');
            Route::delete('/jemaats/{jemaat}', [JemaatManagementController::class, 'destroy'])->middleware('throttle:api-write');
            Route::get('/kk-registrations', [KKRegistrationController::class, 'index']);
            Route::post('/kk-registrations', [KKRegistrationController::class, 'store'])->middleware('throttle:api-write');
            Route::get('/kk-registrations/{kk}', [KKRegistrationController::class, 'show']);
            Route::put('/kk-registrations/{kk}', [KKRegistrationController::class, 'update'])->middleware('throttle:api-write');
            Route::delete('/kk-registrations/{kk}', [KKRegistrationController::class, 'destroy'])->middleware('throttle:api-write');
            Route::post('/news', [NewsController::class, 'store'])->middleware('throttle:api-write');
            Route::put('/news/{news}', [NewsController::class, 'update'])->middleware('throttle:api-write');
            Route::delete('/news/{news}', [NewsController::class, 'destroy'])->middleware('throttle:api-write');
            Route::post('/news/{news}/attachments', [NewsController::class, 'uploadAttachments'])->middleware('throttle:api-write');
            Route::put('/church/profile', [ChurchProfileController::class, 'upsert'])->middleware('throttle:api-write');
            Route::post('/events', [EventController::class, 'store'])->middleware('throttle:api-write');
            Route::put('/events/{event}', [EventController::class, 'update'])->middleware('throttle:api-write');
            Route::delete('/events/{event}', [EventController::class, 'destroy'])->middleware('throttle:api-write');
            Route::post('/events/{event}/documentation', [EventController::class, 'uploadDocumentation'])->middleware('throttle:api-write');
            Route::post('/events/categories', [EventCategoryController::class, 'store'])->middleware('throttle:api-write');
            Route::put('/events/categories/{category}', [EventCategoryController::class, 'update'])->middleware('throttle:api-write');
            Route::delete('/events/categories/{category}', [EventCategoryController::class, 'destroy'])->middleware('throttle:api-write');
            Route::post('/services/forms', [ServiceController::class, 'upsertTemplate'])->middleware('throttle:api-write');
            Route::put('/services/forms/{category}', [ServiceController::class, 'upsertTemplate'])->middleware('throttle:api-write');
            Route::delete('/services/forms/{category}', [ServiceController::class, 'destroyTemplate'])->middleware('throttle:api-write');
            Route::patch('/services/applications/{application}', [ServiceController::class, 'updateApplication'])->middleware('throttle:api-write');
            Route::patch('/services/applications/{application}/status', [ServiceController::class, 'updateStatus'])->middleware('throttle:api-write');
            Route::post('/notifications/broadcast', [NotificationController::class, 'broadcast'])->middleware('throttle:broadcast');
        });
    });
});
