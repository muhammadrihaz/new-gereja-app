<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\UserDevice;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class GoogleAuthController extends Controller
{
    use ApiResponse;

    public function signIn(Request $request): JsonResponse
    {
        $token = $request->string('id_token')->toString();

        try {
            // Validate Google ID token
            $client = new \Google\Client();
            $client->setClientId(config('services.google.client_id'));
            $ticket = $client->verifyIdToken($token);

            if (!$ticket) {
                return $this->errorResponse(
                    'Token Google tidak valid',
                    'INVALID_GOOGLE_TOKEN',
                    401
                );
            }

            $payload = $ticket->getPayload();
            $googleId = $payload['sub'];
            $email = $payload['email'];
            $name = $payload['name'] ?? $email;

            // Find or create user
            $user = User::query()
                ->where('email', $email)
                ->orWhere('google_id', $googleId)
                ->first();

            if (!$user) {
                // Create new user with JUST email
                $user = User::query()->create([
                    'name' => $name,
                    'email' => $email,
                    'google_id' => $googleId,
                    'password' => bcrypt(Str::random()),
                    'role' => 'jemaat',
                    'status' => 'active',
                ]);
            } else {
                // Link Google ID if not already linked
                if (!$user->google_id) {
                    $user->update(['google_id' => $googleId]);
                }
            }

            // Store FCM token
            if ($request->has('fcm_token')) {
                UserDevice::query()->updateOrCreate(
                    ['fcm_token' => $request->string('fcm_token')->toString()],
                    [
                        'user_id' => $user->id,
                        'device_name' => $request->userAgent() ?? 'Unknown',
                        'device_type' => 'mobile',
                        'last_active' => now(),
                    ]
                );
            }

            $token = $user->createToken('google-auth-token')->plainTextToken;

            return $this->successResponse([
                'token' => $token,
                'role' => $user->role,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                ],
            ], 'Login Google berhasil', 200);
        } catch (\Exception $e) {
            return $this->errorResponse(
                'Autentikasi Google gagal',
                'GOOGLE_AUTH_ERROR',
                401
            );
        }
    }
}
