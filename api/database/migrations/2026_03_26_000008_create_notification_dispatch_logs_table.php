<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notification_dispatch_logs', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('sender_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('recipient_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('fcm_token', 255);
            $table->string('module', 80);
            $table->string('event_type', 80);
            $table->string('title', 255);
            $table->text('message');
            $table->json('context')->nullable();
            $table->enum('status', ['queued', 'sent', 'failed'])->default('sent');
            $table->timestamps();

            $table->index(['module', 'event_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_dispatch_logs');
    }
};
