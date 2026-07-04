import 'package:intl/intl.dart';

/// Format tanggal untuk UI aplikasi GPI Yehuda.
/// Default: EEEE, d MMMM y (contoh: Senin, 6 Juli 2026) dalam aksara Indonesia
/// Use [useLong] untuk format timestamp YYYY-MM-DD HH:mm:ss GMT+8.
String formatTanggal(DateTime? date, {bool includeTime = false, bool useLong = false}) {
  if (date == null) return '-';
  if (useLong) {
    return formatTimestampLong(date);
  }
  final datePart = DateFormat('EEEE, d MMMM y', 'id_ID').format(date);
  if (!includeTime) return datePart;
  final timePart = DateFormat('HH:mm').format(date);
  return '$datePart $timePart WITA';
}

/// Format YYYY-MM-DD HH:mm:ss GMT+8 (WITA).
String formatTimestampLong(DateTime date) {
  String two(int x) => x.toString().padLeft(2, '0');
  final tanggal =
      '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
  final jam =
      '${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
  return '$tanggal $jam GMT+8';
}

/// Parse string ISO8601 ke DateTime lalu format ke EEEE, d MMMM y
/// Tambahkan includeTime=true jika perlu menampilkan jam:menit WITA.
/// Tambahkan useLong=true untuk format YYYY-MM-DD HH:mm:ss GMT+8.
String formatTanggalString(String? dateStr, {bool includeTime = false, bool useLong = false}) {
  if (dateStr == null || dateStr.isEmpty) return '-';
  final parsed = DateTime.tryParse(dateStr);
  if (parsed == null) return dateStr;
  final wita = parsed.toUtc().add(const Duration(hours: 8));
  if (useLong) return formatTimestampLong(wita);
  return formatTanggal(wita, includeTime: includeTime);
}

/// Format DateTime ke ISO8601 tanpa milisecond (untuk payload API).
String formatDateApi(DateTime? date) {
  if (date == null) return '';
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}Z';
}

/// Format DateTime ke yyyy-MM-dd (untuk input/date picker label).
String formatDateLabel(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('yyyy-MM-dd').format(date);
}
