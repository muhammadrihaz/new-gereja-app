import 'dart:io';
import 'dart:typed_data';

Future<String> saveDownloadedBytes({
  required Uint8List bytes,
  required String fileName,
}) async {
  final file = File('${Directory.systemTemp.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
