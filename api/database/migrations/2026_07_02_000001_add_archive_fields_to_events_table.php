<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('events', function (Blueprint $table): void {
            if (! Schema::hasColumn('events', 'is_archived')) {
                $table->boolean('is_archived')->default(false)->after('category');
            }
            if (! Schema::hasColumn('events', 'archived_at')) {
                $table->timestampTz('archived_at')->nullable()->after('is_archived');
            }
        });

        Schema::table('events', function (Blueprint $table): void {
            $table->index('is_archived');
            $table->index('start_at');
            $table->index('end_at');
        });
    }

    public function down(): void
    {
        Schema::table('events', function (Blueprint $table): void {
            $table->dropIndex(['is_archived']);
            $table->dropIndex(['start_at']);
            $table->dropIndex(['end_at']);
            $table->dropColumn(['is_archived', 'archived_at']);
        });
    }
};
