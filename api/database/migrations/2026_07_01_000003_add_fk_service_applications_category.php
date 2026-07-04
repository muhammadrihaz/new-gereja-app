<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('service_applications', function (Blueprint $table): void {
            $table->foreign('category')
                ->references('code')
                ->on('service_categories')
                ->restrictOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('service_applications', function (Blueprint $table): void {
            $table->dropForeign(['category']);
        });
    }
};
