<?php

namespace App\Http\Controllers;

use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\UploadProfilePhotoRequest;
use App\Http\Requests\Auth\UpdateProfileRequest;
use App\Models\KKRegistration;
use App\Models\User;
use App\Models\UserDevice;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class AuthController extends Controller
{
    use ApiResponse;

    public function register(RegisterRequest $request): JsonResponse
    {
        $name = trim($request->string('name')->toString());
        $nomorKk = trim($request->string('nomor_kk')->toString());
        $normalizedName = self::normalizeName($name);

        $registeredKk = KKRegistration::query()
            ->where('nomor_kk', $nomorKk)
            ->first(['nama_kepala_keluarga']);

        $isHeadOfFamily = $registeredKk !== null
            && self::normalizeName((string) $registeredKk->nama_kepala_keluarga) === $normalizedName;

        $existingUser = User::query()
            ->where('nomor_kk', $nomorKk)
            ->get()
            ->first(function (User $member) use ($normalizedName) {
                return self::normalizeName((string) $member->name) === $normalizedName;
            });

        $isRegisteredMember = $existingUser !== null;

        if (! $isHeadOfFamily && ! $isRegisteredMember) {
            return $this->errorResponse(
                'Nomor KK atau nama lengkap tidak terdaftar, periksa ulang apakah sudah benar',
                'KK_OR_NAME_NOT_REGISTERED',
                422
            );
        }

        $email = $request->string('email')->toString() ?: $request->string('username')->toString() . '@placeholder.local';

        if ($existingUser) {
            $existingUser->update([
                'username' => $request->string('username')->toString(),
                'email' => $email,
                'password' => $request->string('password')->toString(),
            ]);
            $user = $existingUser;
        } else {
            $user = User::query()->create([
                'name' => $name,
                'username' => $request->string('username')->toString(),
                'email' => $email,
                'password' => $request->string('password')->toString(),
                'nomor_kk' => $nomorKk,
                'jenis_kelamin' => $request->string('jenis_kelamin')->toString() ?: null,
                'usia' => $request->integer('usia') ?: null,
                'alamat' => $request->string('alamat')->toString() ?: ($registeredKk->alamat ?? null),
                'phone_number' => $request->string('phone_number')->toString() ?: ($registeredKk->phone_number ?? null),
                'status' => $request->string('status')->toString() ?: 'active',
                'role' => 'jemaat',
            ]);
        }

        UserDevice::query()->updateOrCreate(
            ['fcm_token' => $request->string('fcm_token')->toString()],
            [
                'user_id' => $user->id,
                'device_name' => mb_substr($request->userAgent() ?: 'Unknown Device', 0, 120),
                'device_type' => 'web',
                'last_active' => now(),
            ]
        );

        $token = $user->createToken('auth-token')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'role' => $user->role,
            'user' => $this->userPayload($user->fresh()),
        ], 'Registrasi berhasil', 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $identifier = $request->string('username')->toString();

        // Check if identifier is email or username
        $user = str_contains($identifier, '@')
            ? User::query()->where('email', $identifier)->first()
            : User::query()->where('username', $identifier)->first();

        if (! $user || ! Hash::check($request->string('password')->toString(), $user->password)) {
            return $this->errorResponse('Username atau password salah', 'INVALID_CREDENTIALS', 401);
        }

        UserDevice::query()->updateOrCreate(
            ['fcm_token' => $request->string('fcm_token')->toString()],
            [
                'user_id' => $user->id,
                'device_name' => mb_substr($request->userAgent() ?: 'Unknown Device', 0, 120),
                'device_type' => 'web',
                'last_active' => now(),
            ]
        );

        $token = $user->createToken('auth-token')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'role' => $user->role,
            'user' => $this->userPayload($user->fresh()),
        ]);
    }

    public function me(): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();

        return $this->successResponse($this->userPayload($user));
    }

    public function logout(): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();
        $user->tokens()->delete();

        return $this->successResponse(null, 'Logout berhasil');
    }

    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();

        $updateData = [
            'name' => $request->string('name')->toString() ?: $user->name,
            'username' => $request->string('username')->toString() ?: $user->username,
            'email' => $request->string('email')->toString() ?: $user->email,
            'nomor_kk' => $request->string('nomor_kk')->toString() ?: $user->nomor_kk,
            'jenis_kelamin' => $request->string('jenis_kelamin')->toString() ?: $user->jenis_kelamin,
            'usia' => $request->integer('usia') ?: $user->usia,
            'alamat' => $request->string('alamat')->toString() ?: $user->alamat,
            'phone_number' => $request->string('phone_number')->toString() ?: $user->phone_number,
            'status' => $request->string('status')->toString() ?: ($user->status ?: 'active'),
        ];

        if ($request->string('password')->toString()) {
            $updateData['password'] = $request->string('password')->toString();
        }

        $user->update($updateData);

        return $this->successResponse($this->userPayload($user->fresh()), 'Profil berhasil diperbarui');
    }

    public function uploadProfilePhoto(UploadProfilePhotoRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();

        if ($user->profile_photo_path) {
            Storage::disk('public')->delete($user->profile_photo_path);
        }

        $path = $request->file('photo')->store('profile-photos', 'public');
        $user->update(['profile_photo_path' => $path]);

        return $this->successResponse($this->userPayload($user->fresh()), 'Foto profil berhasil diperbarui');
    }

    private function userPayload(User $user): array
    {
        $payload = $user->toArray();
        $photoPath = $user->profile_photo_path;
        $profilePhotoUrl = null;

        if ($photoPath) {
            $profilePhotoUrl = $this->resolvePhotoUrl($photoPath);
        }

        $payload['profile_photo_url'] = $profilePhotoUrl;

        return $payload;
    }

    private function resolvePhotoUrl(string $path): string
    {
        $disk = Storage::disk('public');
        $diskUrl = $disk->url($path);

        if (! str_starts_with($diskUrl, 'http://') && ! str_starts_with($diskUrl, 'https://')) {
            $base = rtrim(config('app.url', ''), '/');
            if ($base) {
                return $base . '/' . ltrim($diskUrl, '/');
            }

            $request = request();
            if ($request) {
                $base = $request->getSchemeAndHttpHost();
                return $base . '/' . ltrim($diskUrl, '/');
            }

            return $diskUrl;
        }

        return $diskUrl;
    }

    public static function normalizeName(string $value): string
    {
        $collapsed = preg_replace('/\s+/u', ' ', trim($value)) ?? trim($value);

        return mb_strtolower($collapsed);
    }
}
