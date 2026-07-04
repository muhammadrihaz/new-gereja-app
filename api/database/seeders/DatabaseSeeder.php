<?php

namespace Database\Seeders;

use App\Models\Event;
use App\Models\EventCategory;
use App\Models\KKRegistration;
use App\Models\ServiceCategory;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Admin user — password di-hash eksplisit, bypass cast 'hashed'
        $admin = User::query()->updateOrCreate(
            ['username' => env('ADMIN_USERNAME', 'admin_yehuda')],
            [
                'name' => env('ADMIN_NAME', 'Admin GPI Yehuda'),
                'email' => env('ADMIN_EMAIL', 'admin@example.com'),
                'password' => Hash::make('password123'),
                'role' => 'admin',
                'nomor_kk' => '5171010000000001',
                'jenis_kelamin' => 'L',
                'usia' => 33,
                'alamat' => 'Denpasar, Bali',
            ]
        );

        // Jemaat user
        $jemaat = User::query()->updateOrCreate(
            ['username' => 'jemaat_yehuda'],
            [
                'name' => 'Jemaat GPI Yehuda',
                'email' => 'jemaat@example.com',
                'password' => Hash::make('password123'),
                'role' => 'jemaat',
                'nomor_kk' => '5171010000000002',
                'jenis_kelamin' => 'P',
                'usia' => 27,
                'alamat' => 'Badung, Bali',
            ]
        );

        // KK Registrations
        KKRegistration::query()->updateOrCreate(
            ['nomor_kk' => '5171010000000001'],
            ['nama_kepala_keluarga' => 'Admin GPI Yehuda', 'registered_by' => $admin->id]
        );

        KKRegistration::query()->updateOrCreate(
            ['nomor_kk' => '5171010000000002'],
            ['nama_kepala_keluarga' => 'Jemaat GPI Yehuda', 'registered_by' => $admin->id]
        );

        // Event Categories
        $eventCategories = [
            ['code' => 'ibadah', 'name' => 'Ibadah', 'sort_order' => 1],
            ['code' => 'persekutuan', 'name' => 'Persekutuan', 'sort_order' => 2],
            ['code' => 'doa', 'name' => 'Doa', 'sort_order' => 3],
            ['code' => 'pelayanan_sosial', 'name' => 'Pelayanan Sosial', 'sort_order' => 4],
        ];
        foreach ($eventCategories as $cat) {
            EventCategory::query()->updateOrCreate(
                ['code' => $cat['code']],
                array_merge($cat, ['is_active' => true])
            );
        }

        // Service Categories
        $serviceCategories = [
            ['code' => 'baptisan', 'name' => 'Baptisan', 'sort_order' => 1],
            ['code' => 'pernikahan', 'name' => 'Pernikahan', 'sort_order' => 2],
            ['code' => 'penyerahan_anak', 'name' => 'Penyerahan Anak', 'sort_order' => 3],
            ['code' => 'permohonan_doa', 'name' => 'Permohonan Doa', 'sort_order' => 4],
        ];
        foreach ($serviceCategories as $cat) {
            ServiceCategory::query()->updateOrCreate(
                ['code' => $cat['code']],
                array_merge($cat, ['is_active' => true])
            );
        }

        // Sample event
        if (!Event::query()->exists()) {
            Event::query()->create([
                'title' => 'Ibadah Raya Mingguan',
                'description' => 'Ibadah raya mingguan GPI Yehuda',
                'start_at' => now()->addDays(7)->setHour(9)->setMinute(0),
                'end_at' => now()->addDays(7)->setHour(11)->setMinute(0),
                'category' => 'ibadah',
                'location' => [
                    'address' => 'GPI Yehuda, Jl. Sunset Road No. 767, Denpasar, Bali',
                    'latitude' => -8.670458,
                    'longitude' => 115.212629,
                ],
                'created_by' => $admin->id,
            ]);
        }
    }
}
