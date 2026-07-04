<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class FcmAuthService
{
    public function getAccessToken(): string
    {
        return Cache::remember('fcm_access_token', 3300, function () {
            $serviceAccount = $this->loadServiceAccount();
            $jwt = $this->createJwt($serviceAccount);

            $response = Http::asForm()->timeout(10)->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion'  => $jwt,
            ]);

            if (! $response->successful()) {
                throw new RuntimeException(
                    'FCM OAuth token failed: ' . $response->body()
                );
            }

            return (string) $response->json('access_token');
        });
    }

    private function loadServiceAccount(): array
    {
        $path = config('services.fcm.service_account_path', '');
        $absolutePath = $path !== '' ? storage_path($path) : null;

        if ($absolutePath === null || ! is_file($absolutePath)) {
            throw new RuntimeException(
                'Firebase service account file not found: ' . ($absolutePath ?? 'not configured')
            );
        }

        $contents = json_decode((string) file_get_contents($absolutePath), true);

        if (! is_array($contents) || empty($contents['client_email']) || empty($contents['private_key'])) {
            throw new RuntimeException('Firebase service account file is invalid or missing required fields.');
        }

        return $contents;
    }

    private function createJwt(array $serviceAccount): string
    {
        $now = time();

        $header = $this->base64UrlEncode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $payload = $this->base64UrlEncode(json_encode([
            'iss'   => $serviceAccount['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud'   => 'https://oauth2.googleapis.com/token',
            'iat'   => $now,
            'exp'   => $now + 3600,
        ]));

        $data = $header . '.' . $payload;

        $signature = '';
        $success = openssl_sign(
            $data,
            $signature,
            $serviceAccount['private_key'],
            OPENSSL_ALGO_SHA256
        );

        if (! $success) {
            throw new RuntimeException('FCM JWT signing failed.');
        }

        return $data . '.' . $this->base64UrlEncode($signature);
    }

    private function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
