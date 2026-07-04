<?php

namespace App\Http\Middleware;

use App\Models\ApiActivityLog;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class ApiActivityLoggingMiddleware
{
    public function handle(Request $request, \Closure $next): Response
    {
        $startedAt = microtime(true);

        /** @var Response $response */
        $response = $next($request);

        $this->persistApiLog($request, $response, $startedAt);

        return $response;
    }

    private function persistApiLog(Request $request, Response $response, float $startedAt): void
    {
        try {
            ApiActivityLog::query()->create([
                'trace_id' => $this->resolveTraceId($request),
                'method' => $request->method(),
                'path' => '/' . ltrim($request->path(), '/'),
                'route_name' => optional($request->route())->getName(),
                'query_params' => $this->sanitizePayload($request->query()),
                'request_body' => $this->sanitizePayload($request->except(['password', 'password_confirmation'])),
                'response_body' => $this->extractResponseBody($response),
                'status_code' => $response->getStatusCode(),
                'duration_ms' => (int) round((microtime(true) - $startedAt) * 1000),
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'user_id' => optional($request->user())->id,
            ]);
        } catch (Throwable) {
            // Never break API response flow when activity logging fails.
        }
    }

    private function resolveTraceId(Request $request): ?string
    {
        $traceId = $request->attributes->get('trace_id') ?? $request->header('X-Trace-Id');

        return is_string($traceId) ? $traceId : null;
    }

    /**
     * @param mixed $payload
     *
     * @return mixed
     */
    private function sanitizePayload(mixed $payload): mixed
    {
        if (is_array($payload)) {
            $output = [];

            foreach ($payload as $key => $value) {
                if (is_string($key) && in_array(strtolower($key), ['password', 'password_confirmation', 'token', 'access_token', 'fcm_token'], true)) {
                    $output[$key] = '[redacted]';
                    continue;
                }

                $output[$key] = $this->sanitizePayload($value);
            }

            return $output;
        }

        if ($payload instanceof UploadedFile) {
            return [
                'file_name' => $payload->getClientOriginalName(),
                'mime' => $payload->getClientMimeType(),
                'size' => $payload->getSize(),
            ];
        }

        if (is_string($payload) && strlen($payload) > 500) {
            return substr($payload, 0, 500) . '...[truncated]';
        }

        return $payload;
    }

    private function extractResponseBody(Response $response): array
    {
        $decoded = json_decode($response->getContent() ?: '', true);

        if (! is_array($decoded)) {
            return [];
        }

        return [
            'status' => $decoded['status'] ?? null,
            'error_code' => $decoded['error_code'] ?? null,
            'message' => $decoded['message'] ?? null,
            'trace_id' => $decoded['trace_id'] ?? null,
        ];
    }
}
