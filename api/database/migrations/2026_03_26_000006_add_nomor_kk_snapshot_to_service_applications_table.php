<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('service_applications', function (Blueprint $table): void {
            $table->string('nomor_kk_snapshot', 32)->nullable()->after('user_id');
            $table->index('nomor_kk_snapshot');
        });
    }

    public function down(): void
    {
        Schema::table('service_applications', function (Blueprint $table): void {
            $table->dropIndex(['nomor_kk_snapshot']);
            $table->dropColumn('nomor_kk_snapshot');
        });
    }
};
