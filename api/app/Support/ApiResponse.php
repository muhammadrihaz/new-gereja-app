<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;

trait ApiResponse
{
    protected function successResponse(mixed $data = null, string $message = 'Operasi berhasil', int $status = 200, array $extra = []): JsonResponse
    {
        $payload = array_merge([
            'status' => 'success',
            'message' => $message,
            'data' => $data,
            'trace_id' => request()->header('X-Trace-Id') ?? request()->attributes->get('trace_id'),
        ], $extra);

        return response()->json($payload, $status);
    }

    protected function errorResponse(string $message, string $code, int $status, array $errors = []): JsonResponse
    {
        $payload = [
            'status' => 'error',
            'error_code' => $code,
            'message' => $message,
            'trace_id' => request()->header('X-Trace-Id') ?? request()->attributes->get('trace_id'),
        ];

        if ($errors !== []) {
            $payload['errors'] = $errors;
        }

        return response()->json($payload, $status);
    }
}
