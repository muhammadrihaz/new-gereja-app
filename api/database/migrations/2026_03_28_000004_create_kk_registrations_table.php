<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('kk_registrations', function (Blueprint $table): void {
            $table->id();
            $table->string('nomor_kk', 32)->unique()->index();
            $table->string('nama_kepala_keluarga', 160);
            $table->text('alamat')->nullable();
            $table->string('phone_number', 20)->nullable();
            $table->foreignId('registered_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('kk_registrations');
    }
};
