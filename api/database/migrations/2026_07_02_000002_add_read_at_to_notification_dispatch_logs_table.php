<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notification_dispatch_logs', function (Blueprint $table): void {
            if (! Schema::hasColumn('notification_dispatch_logs', 'read_at')) {
                $table->timestampTz('read_at')->nullable()->after('provider_response');
            }
        });

        Schema::table('notification_dispatch_logs', function (Blueprint $table): void {
            $table->index(['recipient_user_id', 'read_at']);
            $table->index(['recipient_user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::table('notification_dispatch_logs', function (Blueprint $table): void {
            $table->dropIndex(['recipient_user_id', 'read_at']);
            $table->dropIndex(['recipient_user_id', 'created_at']);
            $table->dropColumn('read_at');
        });
    }
};
