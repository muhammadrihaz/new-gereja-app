<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__ . '/../routes/web.php',
        api: __DIR__ . '/../routes/api.php',
        commands: __DIR__ . '/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->statefulApi();
        $middleware->append(\App\Http\Middleware\TraceIdMiddleware::class);
        $middleware->append(\App\Http\Middleware\ApiActivityLoggingMiddleware::class);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (ValidationException $e, $request) {
            return response()->json([
                'status' => 'error',
                'error_code' => 'VALIDATION_ERROR',
                'message' => 'Validasi gagal',
                'trace_id' => $request->header('X-Trace-Id') ?? $request->attributes->get('trace_id'),
                'errors' => $e->errors(),
            ], 422);
        });

        $exceptions->render(function (AuthenticationException $e, $request) {
            return response()->json([
                'status' => 'error',
                'error_code' => 'UNAUTHORIZED',
                'message' => 'Unauthorized',
                'trace_id' => $request->header('X-Trace-Id') ?? $request->attributes->get('trace_id'),
            ], 401);
        });

        $exceptions->render(function (AccessDeniedHttpException $e, $request) {
            return response()->json([
                'status' => 'error',
                'error_code' => 'FORBIDDEN',
                'message' => 'Forbidden',
                'trace_id' => $request->header('X-Trace-Id') ?? $request->attributes->get('trace_id'),
            ], 403);
        });

        $exceptions->render(function (NotFoundHttpException $e, $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'status' => 'error',
                    'error_code' => 'NOT_FOUND',
                    'message' => 'Resource tidak ditemukan',
                    'trace_id' => $request->header('X-Trace-Id') ?? $request->attributes->get('trace_id'),
                ], 404);
            }
        });
    })->create();
