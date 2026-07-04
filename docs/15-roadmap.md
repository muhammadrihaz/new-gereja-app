# 15 - Roadmap

## 🔴 Critical

| #   | Item                                                         | Alasan                                                    | Estimasi |
| --- | ------------------------------------------------------------ | --------------------------------------------------------- | -------- |
| 1   | Fix hardcoded credentials di Flutter                         | Security risk jika terekspos di production                | 1 hari   |
| 2   | Fix `admin_notes` typo di ServiceApplicationExportController | CSV export tidak menghasilkan data admin note             | 15 menit |
| 3   | Implementasi PDF export yang proper (bukan placeholder)      | Endpoint ada tapi error karena file placeholder tidak ada | 1-2 hari |
| 4   | Batasi CORS origins di production                            | Security — semua domain bisa akses API                    | 30 menit |
| 5   | Hapus `.env.production` dan `.env.test` dari repository      | Credentials production bisa terekspos                     | 30 menit |

## 🟡 High

| #   | Item                                                | Alasan                                    | Estimasi |
| --- | --------------------------------------------------- | ----------------------------------------- | -------- |
| 6   | Implementasi Password Reset                         | User yang lupa password tidak bisa masuk  | 2-3 hari |
| 7   | Validasi event category di EventController          | Event bisa dibuat dengan kategori invalid | 1 jam    |
| 8   | Hapus duplicate `Kernel.php` schedule               | Dead code / membingungkan developer       | 30 menit |
| 9   | Hapus model `Documentation` yang unused             | Dead code                                 | 15 menit |
| 10  | Extract `resolveStoredAbsolutePath` ke shared trait | Duplicate code di 2 controller            | 1 jam    |
| 11  | Tambahkan file upload MIME type validation          | Security — upload tanpa validasi MIME     | 2 jam    |
| 12  | Escape LIKE wildcard di search queries              | Bisa dieksploitasi untuk slow queries     | 1 jam    |

## 🟢 Medium

| #   | Item                                        | Alasan                                            | Estimasi |
| --- | ------------------------------------------- | ------------------------------------------------- | -------- |
| 13  | Implementasi Google Sign-In                 | Placeholder sudah ada, mempermudah registrasi     | 3-5 hari |
| 14  | Implementasi Attendance Module              | Tracking kehadiran event                          | 5-7 hari |
| 15  | Implementasi Laravel Policy/Gate konsisten  | Saat ini auth check manual di beberapa controller | 2-3 hari |
| 16  | Tambahkan API versioning header             | Future-proof untuk API v2                         | 1 hari   |
| 17  | Implementasi unit test yang lebih lengkap   | Test coverage rendah                              | 5-7 hari |
| 18  | Implementasi image compression saat upload  | Foto profil dan cover image bisa besar            | 2 hari   |
| 19  | Implementasi soft delete pada model penting | Prevent data loss accidental                      | 2-3 hari |

## 🔵 Low

| #   | Item                                          | Alasan                          | Estimasi   |
| --- | --------------------------------------------- | ------------------------------- | ---------- |
| 20  | PWA optimization (offline mode, web manifest) | Scaffold sudah ada              | 3-5 hari   |
| 21  | Multi-language support (ID/EN)                | Saat ini hanya Bahasa Indonesia | 5-7 hari   |
| 22  | Analytics dashboard                           | Statistik penggunaan            | 5-7 hari   |
| 23  | Chat/Messaging antar jemaat                   | Komunikasi langsung             | 10-15 hari |
| 24  | Perpuluhan/Tithe Management                   | Pencatatan persembahan          | 7-10 hari  |
| 25  | Multi-church support                          | Satu platform banyak gereja     | 15-20 hari |
| 26  | Jadwal ibadah & kalender                      | Kalender mingguan/bulanan       | 5-7 hari   |
| 27  | WebSocket real-time updates                   | Saat ini polling/manual refresh | 5-7 hari   |
