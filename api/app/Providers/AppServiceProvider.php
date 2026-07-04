<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::define('admin', fn($user) => $user->role === 'admin');

        RateLimiter::for('auth-login', fn(Request $request) => [
            Limit::perMinute(30)->by($request->ip() . '|' . (string) $request->input('username')),
            Limit::perHour(200)->by($request->ip()),
        ]);

        RateLimiter::for('auth-register', fn(Request $request) => [
            Limit::perMinute(10)->by($request->ip()),
            Limit::perHour(50)->by($request->ip()),
        ]);

        RateLimiter::for('broadcast', fn(Request $request) => [
            Limit::perMinute(5)->by((string) optional($request->user())->id),
            Limit::perHour(60)->by((string) optional($request->user())->id),
        ]);

        RateLimiter::for('api-write', fn(Request $request) => [
            Limit::perMinute(30)->by((string) optional($request->user())->id ?: $request->ip()),
        ]);

        RateLimiter::for('api-default', fn(Request $request) => [
            Limit::perMinute(60)->by((string) optional($request->user())->id ?: $request->ip()),
        ]);
    }
}
