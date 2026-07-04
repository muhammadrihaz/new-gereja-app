<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $driver = DB::connection()->getDriverName();

        if ($driver === 'sqlite') {
            // Laravel 12+ supports native ALTER on sqlite via schema change().
            Schema::table('events', function (Blueprint $table): void {
                $table->dateTime('date')->nullable()->change();
            });
            return;
        }

        DB::statement('ALTER TABLE events MODIFY date DATETIME NULL');
    }

    public function down(): void
    {
        $driver = DB::connection()->getDriverName();

        if ($driver === 'sqlite') {
            Schema::table('events', function (Blueprint $table): void {
                $table->dateTime('date')->nullable(false)->change();
            });
            return;
        }

        DB::statement('ALTER TABLE events MODIFY date DATETIME NOT NULL');
    }
};
