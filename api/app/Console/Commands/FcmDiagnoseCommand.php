<?php

namespace App\Console\Commands;

use App\Services\FcmAccessTokenProvider;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

/**
 * Diagnoses the FCM HTTP v1 configuration end-to-end WITHOUT sending a
 * notification. Useful in production to confirm the service account works.
 *
 * Usage:
 *   php artisan fcm:diagnose
 */
class FcmDiagnoseCommand extends Command
{
    protected $signature = 'fcm:diagnose {--json : Emit machine-readable JSON output}';

    protected $description = 'Diagnose FCM HTTP v1 configuration: env, credentials, OAuth2 token, project id.';

    public function handle(FcmAccessTokenProvider $provider): int
    {
        $report = [
            'fcm_enabled' => filter_var((string) config('services.fcm.enabled', false), FILTER_VALIDATE_BOOL),
            'credentials_source' => null,
            'project_id' => null,
            'access_token_obtained' => false,
            'access_token_length' => 0,
            'reachability' => null,
            'legacy_configured' => (string) config('services.fcm.server_key', '') !== '',
            'warnings' => [],
            'errors' => [],
        ];

        // Identify the credentials source.
        $path = (string) config('services.fcm.credentials_json', '');
        $base64 = (string) config('services.fcm.credentials_base64', '');
        if ($path !== '' && is_file($path) && is_readable($path)) {
            $report['credentials_source'] = "file:{$path}";
        } elseif ($base64 !== '') {
            $report['credentials_source'] = 'env:FCM_CREDENTIALS_BASE64';
        } else {
            $report['errors'][] = 'No FCM_CREDENTIALS_JSON path or FCM_CREDENTIALS_BASE64 configured. Push v1 will not work.';
        }

        if (! $report['fcm_enabled']) {
            $report['warnings'][] = 'FCM_ENABLED is false. No push notifications will be sent regardless of credentials.';
        }

        if ($report['legacy_configured']) {
            $report['warnings'][] = 'FCM_SERVER_KEY is set. The legacy API is deprecated by Google since 2024-06-20 and will not work in production. Use FCM v1 credentials instead.';
        }

        // Try to fetch an OAuth2 access token.
        if ($report['credentials_source'] !== null) {
            $auth = $provider->fetch();
            if ($auth !== null) {
                $report['access_token_obtained'] = true;
                $report['access_token_length'] = strlen($auth['token']);
                $report['project_id'] = $auth['project_id'];
            } else {
                $report['errors'][] = 'Failed to obtain an OAuth2 access token from Google. Check that the service account JSON has the "Firebase Cloud Messaging API" enabled and has the "roles/firebasecloudmessaging.admin" role.';
            }
        }

        // Optional reachability probe (does not send a message).
        try {
            $probe = Http::timeout(4)->get('https://fcm.googleapis.com/v1/');
            $report['reachability'] = ['status' => $probe->status(), 'ok' => true];
        } catch (\Throwable $e) {
            $report['reachability'] = ['status' => null, 'ok' => false, 'error' => $e->getMessage()];
            $report['warnings'][] = 'Could not reach fcm.googleapis.com: ' . $e->getMessage();
        }

        if ($this->option('json')) {
            $this->line(json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) ?: '{}');
            return count($report['errors']) === 0 ? self::SUCCESS : self::FAILURE;
        }

        $this->info('FCM HTTP v1 Diagnostic Report');
        $this->line('----------------------------------------');
        $this->line('FCM enabled           : ' . ($report['fcm_enabled'] ? 'yes' : 'NO'));
        $this->line('Credentials source    : ' . ($report['credentials_source'] ?? '<none>'));
        $this->line('Project ID            : ' . ($report['project_id'] ?? '<unknown>'));
        $this->line('Access token obtained : ' . ($report['access_token_obtained'] ? 'yes' : 'NO'));
        if ($report['access_token_obtained']) {
            $this->line('Access token length   : ' . $report['access_token_length']);
        }
        $this->line('Google reachability   : ' . (($report['reachability']['ok'] ?? false) ? 'ok (' . ($report['reachability']['status'] ?? '-') . ')' : 'unreachable'));
        $this->line('Legacy server key set : ' . ($report['legacy_configured'] ? 'yes (deprecated)' : 'no'));

        foreach ($report['warnings'] as $w) {
            $this->warn('WARNING: ' . $w);
        }
        foreach ($report['errors'] as $e) {
            $this->error('ERROR: ' . $e);
        }

        return count($report['errors']) === 0 ? self::SUCCESS : self::FAILURE;
    }
}
