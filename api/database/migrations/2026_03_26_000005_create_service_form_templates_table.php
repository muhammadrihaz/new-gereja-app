<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_form_templates', function (Blueprint $table): void {
            $table->id();
            $table->string('category', 80)->unique();
            $table->string('name', 120);
            $table->json('fields');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        $now = now();

        DB::table('service_form_templates')->insert([
            [
                'category' => 'baptisan',
                'name' => 'Form Baptisan',
                'fields' => json_encode([
                    ['key' => 'nama_lengkap', 'type' => 'string', 'required' => true],
                    ['key' => 'tanggal_lahir', 'type' => 'string', 'required' => true],
                    ['key' => 'nama_ayah', 'type' => 'string', 'required' => false],
                    ['key' => 'nama_ibu', 'type' => 'string', 'required' => false],
                ], JSON_THROW_ON_ERROR),
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'category' => 'pernikahan',
                'name' => 'Form Pernikahan',
                'fields' => json_encode([
                    ['key' => 'nama_mempelai_pria', 'type' => 'string', 'required' => true],
                    ['key' => 'nama_mempelai_wanita', 'type' => 'string', 'required' => true],
                    ['key' => 'tanggal_rencana', 'type' => 'string', 'required' => true],
                ], JSON_THROW_ON_ERROR),
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'category' => 'penyerahan_anak',
                'name' => 'Form Penyerahan Anak',
                'fields' => json_encode([
                    ['key' => 'nama_anak', 'type' => 'string', 'required' => true],
                    ['key' => 'tanggal_lahir', 'type' => 'string', 'required' => true],
                    ['key' => 'nama_orang_tua', 'type' => 'string', 'required' => true],
                ], JSON_THROW_ON_ERROR),
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'category' => 'permohonan_doa',
                'name' => 'Form Permohonan Doa',
                'fields' => json_encode([
                    ['key' => 'pokok_doa', 'type' => 'string', 'required' => true],
                    ['key' => 'catatan_tambahan', 'type' => 'string', 'required' => false],
                ], JSON_THROW_ON_ERROR),
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('service_form_templates');
    }
};
