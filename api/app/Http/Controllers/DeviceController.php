<?php

namespace App\Http\Controllers;

use App\Http\Requests\Devices\RefreshDeviceRequest;
use App\Http\Requests\Devices\RegisterDeviceRequest;
use App\Http\Requests\Devices\RevokeDeviceRequest;
use App\Models\User;
use App\Models\UserDevice;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class DeviceController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();
        $currentDeviceToken = request()->header('X-Device-Token');

        $devices = $user->devices()
            ->latest('last_active')
            ->get()
            ->map(function (UserDevice $device) use ($currentDeviceToken): array {
                return [
                    'id' => $device->id,
                    'device_name' => $device->device_name,
                    'device_type' => $device->device_type,
                    'last_active' => optional($device->last_active)->toIso8601String(),
                    'is_current_device' => $currentDeviceToken !== null && $device->fcm_token === $currentDeviceToken,
                ];
            });

        return $this->successResponse($devices, 'Daftar device berhasil diambil');
    }

    public function register(RegisterDeviceRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();

        $device = UserDevice::query()->updateOrCreate(
            ['fcm_token' => $request->string('fcm_token')->toString()],
            [
                'user_id' => $user->id,
                'device_name' => mb_substr($request->string('device_name')->toString(), 0, 120) ?: null,
                'device_type' => $request->string('device_type')->toString(),
                'last_active' => now(),
            ]
        );

        return $this->successResponse($device, 'Device berhasil didaftarkan', 201);
    }

    public function revoke(RevokeDeviceRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();

        $device = $user->devices()->where('fcm_token', $request->string('fcm_token'))->first();

        if (! $device) {
            return $this->errorResponse('Device token tidak ditemukan', 'DEVICE_NOT_FOUND', 404);
        }

        $device->delete();

        return $this->successResponse(null, 'Device berhasil dicabut');
    }

    public function revokeAll(): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();

        $count = $user->devices()->count();
        $user->devices()->delete();

        return $this->successResponse([
            'revoked_count' => $count,
        ], 'Semua device berhasil dicabut');
    }

    /**
     * Idempotent FCM token refresh. Called by the Flutter client when
     * FirebaseMessaging.onTokenRefresh fires or when the app starts and the
     * cached token differs from the freshly-fetched one.
     *
     * Behavior:
     *  - If `old_fcm_token` matches an existing row (any user), that row's
     *    fcm_token is UPDATED in place → preserves history, avoids duplicates.
     *  - Otherwise the row is created via updateOrCreate on `new_fcm_token`.
     *  - `fcm_token` has a UNIQUE index so any stale row previously owned by a
     *    different user is claimed by the current user (Firebase re-issues
     *    tokens after uninstall+reinstall).
     *  - Returns HTTP 200 whether the row was created or updated (idempotent).
     */
    public function refresh(RefreshDeviceRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();

        $oldToken = trim((string) $request->input('old_fcm_token', ''));
        $newToken = trim((string) $request->input('new_fcm_token', ''));
        $deviceName = mb_substr((string) $request->input('device_name', ''), 0, 120) ?: null;
        $deviceType = (string) $request->input('device_type', 'web');

        if ($oldToken === $newToken) {
            $oldToken = '';
        }

        $device = DB::transaction(function () use ($user, $oldToken, $newToken, $deviceName, $deviceType): UserDevice {
            // If a row exists for the new token, reuse it (claim ownership).
            $existingNew = UserDevice::query()->where('fcm_token', $newToken)->first();
            if ($existingNew !== null) {
                $existingNew->update([
                    'user_id' => $user->id,
                    'device_name' => $deviceName ?: $existingNew->device_name,
                    'device_type' => $deviceType,
                    'last_active' => now(),
                ]);
                if ($oldToken !== '') {
                    // Clean up the pre-rotation row so we don't send to a dead token.
                    UserDevice::query()->where('fcm_token', $oldToken)->delete();
                }
                return $existingNew->fresh();
            }

            // Migrate existing row keyed by old token if present.
            if ($oldToken !== '') {
                $existingOld = UserDevice::query()->where('fcm_token', $oldToken)->first();
                if ($existingOld !== null) {
                    $existingOld->update([
                        'user_id' => $user->id,
                        'fcm_token' => $newToken,
                        'device_name' => $deviceName ?: $existingOld->device_name,
                        'device_type' => $deviceType,
                        'last_active' => now(),
                    ]);
                    return $existingOld->fresh();
                }
            }

            return UserDevice::query()->create([
                'user_id' => $user->id,
                'fcm_token' => $newToken,
                'device_name' => $deviceName,
                'device_type' => $deviceType,
                'last_active' => now(),
            ]);
        });

        return $this->successResponse([
            'id' => $device->id,
            'fcm_token' => $device->fcm_token,
            'device_name' => $device->device_name,
            'device_type' => $device->device_type,
            'last_active' => optional($device->last_active)->toIso8601String(),
        ], 'Token FCM berhasil diperbarui');
    }
}
