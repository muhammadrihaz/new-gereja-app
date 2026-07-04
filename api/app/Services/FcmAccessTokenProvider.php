<?php

namespace App\Services;

use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

/**
 * Obtains OAuth2 access tokens for the FCM HTTP v1 API using a Google service account.
 *
 * Configuration keys (config/services.php → 'fcm'):
 *   - credentials_json   Absolute path to a Google service account JSON file
 *   - credentials_base64 Alternative: base64-encoded service account JSON
 *   - project_id         (Optional) firebase project id override; inferred from JSON otherwise.
 *
 * The obtained token is cached for 55 minutes (Google tokens live ~60 minutes).
 */
class FcmAccessTokenProvider
{
    private const CACHE_KEY = 'fcm.v1.access_token';
    private const CACHE_TTL_SECONDS = 55 * 60;
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    /**
     * @return array{token: string, project_id: string}|null Returns null when credentials are not configured.
     */
    public function fetch(): ?array
    {
        $credentials = $this->loadCredentialsArray();
        if ($credentials === null) {
            return null;
        }

        $projectId = (string) (config('services.fcm.project_id') ?: ($credentials['project_id'] ?? ''));
        if ($projectId === '') {
            Log::warning('FCM v1: project_id missing from credentials and config.');
            return null;
        }

        $cacheKey = self::CACHE_KEY . ':' . md5(json_encode($credentials) ?: $projectId);

        try {
            $token = Cache::remember($cacheKey, self::CACHE_TTL_SECONDS, function () use ($credentials): string {
                $sa = new ServiceAccountCredentials(self::SCOPE, $credentials);
                $auth = $sa->fetchAuthToken();
                return (string) ($auth['access_token'] ?? '');
            });
        } catch (\Throwable $e) {
            Log::error('FCM v1: failed to obtain access token', ['error' => $e->getMessage()]);
            return null;
        }

        if ($token === '') {
            return null;
        }

        return ['token' => $token, 'project_id' => $projectId];
    }

    /**
     * Load the service-account JSON as an associative array from either a file path or a base64 string.
     */
    private function loadCredentialsArray(): ?array
    {
        $path = (string) config('services.fcm.credentials_json', '');
        $base64 = (string) config('services.fcm.credentials_base64', '');

        $raw = null;
        if ($path !== '' && is_file($path) && is_readable($path)) {
            $raw = (string) file_get_contents($path);
        } elseif ($base64 !== '') {
            $decoded = base64_decode($base64, true);
            if ($decoded !== false) {
                $raw = $decoded;
            }
        }

        if ($raw === null || $raw === '') {
            return null;
        }

        $arr = json_decode($raw, true);
        if (! is_array($arr) || empty($arr['client_email']) || empty($arr['private_key'])) {
            Log::warning('FCM v1: service account JSON is invalid or incomplete.');
            return null;
        }

        return $arr;
    }
}
