<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
    ],

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'fcm' => [
        'enabled' => env('FCM_ENABLED', false),
        // Legacy HTTP API — DEPRECATED by Google since 2024-06-20. Retained only for
        // backward compatibility with old deployments; new deployments should use the v1 API below.
        'server_key' => env('FCM_SERVER_KEY'),
        'endpoint' => env('FCM_ENDPOINT', 'https://fcm.googleapis.com/fcm/send'),

        // FCM HTTP v1 API configuration.
        // Provide EITHER an absolute path to a Google service-account JSON via FCM_CREDENTIALS_JSON,
        // OR a base64-encoded JSON payload via FCM_CREDENTIALS_BASE64 (useful for env-only deployments).
        // project_id is inferred from the credentials JSON but may be overridden.
        'credentials_json' => env('FCM_CREDENTIALS_JSON'),
        'credentials_base64' => env('FCM_CREDENTIALS_BASE64'),
        'service_account_path' => env('FCM_SERVICE_ACCOUNT_PATH', 'app/firebase-service-account.json'),
        'project_id' => env('FCM_PROJECT_ID'),
    ],

    'notifications' => [
        'email_enabled' => env('EMAIL_NOTIFICATIONS_ENABLED', false),
    ],

];
