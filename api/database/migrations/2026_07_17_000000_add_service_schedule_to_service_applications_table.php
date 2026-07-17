<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('service_applications', function (Blueprint $table): void {
            $table->date('service_date')->nullable()->after('status');
            $table->time('service_time')->nullable()->after('service_date');
        });
    }

    public function down(): void
    {
        Schema::table('service_applications', function (Blueprint $table): void {
            $table->dropColumn(['service_date', 'service_time']);
        });
    }
};
