import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

Future<String> savePdfBytes(Uint8List bytes, String fileName) async {
  final appDirectory = await getApplicationDocumentsDirectory();
  final primaryFile = File('${appDirectory.path}/$fileName');
  await primaryFile.writeAsBytes(bytes, flush: true);
  var savedPath = primaryFile.path;

  try {
    if (Platform.isAndroid) {
      final downloadDirectory = Directory('/storage/emulated/0/Download');
      if (await downloadDirectory.exists()) {
        final downloadFile = File('${downloadDirectory.path}/$fileName');
        await downloadFile.writeAsBytes(bytes, flush: true);
        savedPath = downloadFile.path;
      }
    }
  } catch (_) {
    // The app-owned copy remains available when scoped storage blocks Download.
  }

  return savedPath;
}

Future<void> sharePdfBytes(Uint8List bytes, String fileName) {
  return Printing.sharePdf(bytes: bytes, filename: fileName);
}

Future<Uint8List?> loadAvatarBytes(String value) async {
  if (value.startsWith('data:image/')) {
    final comma = value.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(value.substring(comma + 1));
    } on FormatException {
      return null;
    }
  }

  final file = File(value);
  return await file.exists() ? file.readAsBytes() : null;
}
