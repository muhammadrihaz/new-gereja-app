<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Add 'inactive' to the status enum
        DB::statement("ALTER TABLE users MODIFY COLUMN status ENUM('active', 'inactive', 'jemaat', 'simpatisan') DEFAULT 'active'");
    }

    public function down(): void
    {
        // Revert back (Note: this might fail if any users are currently 'inactive')
        DB::statement("ALTER TABLE users MODIFY COLUMN status ENUM('active', 'jemaat', 'simpatisan') DEFAULT 'active'");
    }
};
