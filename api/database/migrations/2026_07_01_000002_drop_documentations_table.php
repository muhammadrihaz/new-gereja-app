<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::dropIfExists('documentations');
    }

    public function down(): void
    {
        Schema::create('documentations', function ($table) {
            $table->id();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->enum('type', ['documentation', 'article', 'blog'])->default('documentation');
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('file_path')->nullable();
            $table->string('mime_type', 120)->nullable();
            $table->unsignedBigInteger('file_size')->nullable();
            $table->string('gdrive_link')->nullable();
            $table->text('report_summary')->nullable();
            $table->timestamps();
        });
    }
};
