<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <title>Sertifikat Pengajuan Layanan</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 12px; color: #1a1a1a; }
        .header { text-align: center; margin-bottom: 24px; }
        .title { font-size: 20px; font-weight: 700; }
        .subtitle { font-size: 12px; color: #555; }
        .box { border: 1px solid #ddd; padding: 16px; border-radius: 8px; }
        .row { margin-bottom: 8px; }
        .label { font-weight: 700; width: 180px; display: inline-block; }
        .footer { margin-top: 28px; font-size: 11px; color: #555; }
    </style>
</head>
<body>
<div class="header">
    <div class="title">Sertifikat Pengajuan Layanan Jemaat</div>
    <div class="subtitle">Sistem Informasi GPI Yehuda</div>
</div>

<div class="box">
    <div class="row"><span class="label">ID Pengajuan</span>: {{ $application->id }}</div>
    <div class="row"><span class="label">Kategori Layanan</span>: {{ $application->category }}</div>
    <div class="row"><span class="label">Nama Jemaat</span>: {{ $application->user->name ?? $application->user->username }}</div>
    <div class="row"><span class="label">Email</span>: {{ $application->user->email }}</div>
    <div class="row"><span class="label">Nomor KK (Snapshot)</span>: {{ $application->nomor_kk_snapshot }}</div>
    <div class="row"><span class="label">Status</span>: {{ $application->status }}</div>
    <div class="row"><span class="label">Catatan Admin</span>: {{ $application->admin_note ?? '-' }}</div>
    <div class="row"><span class="label">Dibuat Pada</span>: {{ $application->created_at?->format('d-m-Y H:i:s') }}</div>
    <div class="row"><span class="label">Diperbarui Pada</span>: {{ $application->updated_at?->format('d-m-Y H:i:s') }}</div>
</div>

<div class="footer">
    Dokumen ini dihasilkan otomatis oleh sistem dan dapat digunakan sebagai bukti pengajuan layanan jemaat.
</div>
</body>
</html>
