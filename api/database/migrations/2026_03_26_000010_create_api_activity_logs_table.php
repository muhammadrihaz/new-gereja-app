<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('api_activity_logs', function (Blueprint $table): void {
            $table->id();
            $table->string('trace_id', 64)->nullable()->index();
            $table->string('method', 10);
            $table->string('path', 255)->index();
            $table->string('route_name', 120)->nullable();
            $table->json('query_params')->nullable();
            $table->json('request_body')->nullable();
            $table->json('response_body')->nullable();
            $table->unsignedSmallInteger('status_code')->index();
            $table->unsignedInteger('duration_ms')->default(0);
            $table->string('ip_address', 45)->nullable();
            $table->string('user_agent', 255)->nullable();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['method', 'path']);
            $table->index(['created_at', 'status_code']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('api_activity_logs');
    }
};
