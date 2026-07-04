<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notification_dispatch_logs', function (Blueprint $table): void {
            $table->string('provider', 30)->default('fcm')->after('status');
            $table->string('trace_id', 64)->nullable()->after('provider');
            $table->json('provider_response')->nullable()->after('trace_id');

            $table->index('trace_id');
            $table->index('provider');
        });
    }

    public function down(): void
    {
        Schema::table('notification_dispatch_logs', function (Blueprint $table): void {
            $table->dropIndex(['trace_id']);
            $table->dropIndex(['provider']);
            $table->dropColumn(['provider_response', 'trace_id', 'provider']);
        });
    }
};
