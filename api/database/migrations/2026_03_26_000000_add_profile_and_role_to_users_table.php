<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->string('username')->nullable()->unique()->after('id');
            $table->enum('role', ['admin', 'jemaat'])->default('jemaat')->after('password');
            $table->string('nomor_kk', 32)->nullable()->after('role');
            $table->enum('jenis_kelamin', ['L', 'P'])->nullable()->after('nomor_kk');
            $table->unsignedTinyInteger('usia')->nullable()->after('jenis_kelamin');
            $table->text('alamat')->nullable()->after('usia');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->dropColumn(['username', 'role', 'nomor_kk', 'jenis_kelamin', 'usia', 'alamat']);
        });
    }
};
