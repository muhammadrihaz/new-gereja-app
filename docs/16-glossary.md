# 16 - Glossary

## Istilah Domain

| Istilah                 | Deskripsi                                                                                      |
| ----------------------- | ---------------------------------------------------------------------------------------------- |
| **Jemaat**              | Anggota gereja. Role default untuk user yang mendaftar. Bahasa: congregation member            |
| **Admin**               | Pengelola/pengurus gereja. Memiliki akses penuh ke fitur manajemen                             |
| **KK (Kartu Keluarga)** | Dokumen identitas keluarga Indonesia. Nomor KK digunakan sebagai identifier keluarga di sistem |
| **Nomor KK**            | 16-digit nomor identifikasi Kartu Keluarga                                                     |
| **Kepala Keluarga**     | Nama anggota keluarga utama yang terdaftar di KK                                               |
| **Simpatisan**          | Orang yang simpati/dekat dengan gereja tapi belum resmi menjadi jemaat                         |
| **Layanan Gereja**      | Pelayanan administratif gereja (baptis, nikah, sidi, dll)                                      |
| **Pengajuan Layanan**   | Permohonan/request untuk layanan gereja (ServiceApplication)                                   |
| **Broadcast**           | Pengiriman notifikasi massal ke banyak pengguna                                                |
| **Dokumentasi Event**   | File foto/video/dokumen dari kegiatan gereja                                                   |
| **Sertifikat Layanan**  | Dokumen PDF yang dihasilkan setelah layanan di-approve                                         |
| **Profil Gereja**       | Informasi umum gereja (nama, alamat, logo)                                                     |
| **Kategori Event**      | Klasifikasi jenis event (ibadah, persekutuan, dll)                                             |
| **Kategori Layanan**    | Klasifikasi jenis layanan gereja (baptis, nikah, dll)                                          |
| **Template Form**       | Definisi field dinamis untuk form pengajuan layanan                                            |

## Istilah Teknis

| Istilah             | Deskripsi                                                               |
| ------------------- | ----------------------------------------------------------------------- |
| **Sanctum**         | Laravel package untuk API token authentication                          |
| **FCM**             | Firebase Cloud Messaging — layanan push notification dari Google        |
| **FCM Token**       | Token unik per device untuk menerima push notification                  |
| **FCM v1**          | Versi terbaru API FCM yang menggunakan OAuth2 service account           |
| **Trace ID**        | Identifier unik per API request untuk tracking/debugging                |
| **Service Account** | Akun Google Cloud untuk machine-to-machine authentication               |
| **Throttle**        | Rate limiting — membatasi jumlah request per waktu                      |
| **Upsert**          | Update OR Insert — buat baru jika belum ada, update jika sudah          |
| **Archive**         | Menyembunyikan event yang sudah expired dari tampilan jemaat            |
| **Queue**           | Antrian pekerjaan yang dijalankan secara asynchronous                   |
| **Scheduler**       | Penjadwalan task yang berjalan otomatis berdasarkan waktu               |
| **Migration**       | File definisi perubahan schema database                                 |
| **Seeder**          | File untuk mengisi data awal ke database                                |
| **Form Request**    | Class khusus Laravel untuk validasi input HTTP                          |
| **API Resource**    | Class Laravel untuk transformasi model ke JSON response                 |
| **Middleware**      | Layer yang memproses request sebelum mencapai controller                |
| **Eloquent**        | ORM (Object-Relational Mapping) bawaan Laravel                          |
| **Cast**            | Konversi otomatis tipe data field model (JSON, array, datetime, dll)    |
| **Scope**           | Filter query yang bisa di-reuse pada model Eloquent                     |
| **PWA**             | Progressive Web App — web app yang bisa di-install seperti native app   |
| **Mailpit**         | Email testing tool yang menangkap email tanpa mengirim ke penerima asli |
| **Predis**          | PHP client library untuk Redis                                          |
| **DomPDF**          | Library PHP untuk menghasilkan PDF dari HTML                            |
| **Resend**          | Email delivery platform (alternatif SendGrid/Mailgun)                   |
| **Vite**            | Modern frontend build tool                                              |
