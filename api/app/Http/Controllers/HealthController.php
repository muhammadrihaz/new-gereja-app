<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;

class HealthController extends Controller
{
    public function __invoke(): JsonResponse
    {
        return response()->json([
            'status' => 'ok',
            'flutter_ready' => true,
            'api_version' => 'v1',
            'features' => [
                'auth_sanctum' => true,
                'push_notification' => true,
                'email_notification' => filter_var((string) config('services.notifications.email_enabled', false), FILTER_VALIDATE_BOOL),
                'trace_id' => true,
                'rate_limiter' => true,
            ],
        ]);
    }
}
