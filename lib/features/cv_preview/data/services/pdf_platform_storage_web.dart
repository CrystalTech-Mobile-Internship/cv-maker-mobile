import 'dart:convert';
import 'dart:typed_data';

import 'package:printing/printing.dart';

Future<String> savePdfBytes(Uint8List bytes, String fileName) async {
  // Browsers don't expose a stable absolute file path. The actual download is
  // started by [sharePdfBytes] after the CV has been persisted in IndexedDB.
  return 'browser-downloads/$fileName';
}

Future<void> sharePdfBytes(Uint8List bytes, String fileName) {
  return Printing.sharePdf(bytes: bytes, filename: fileName);
}

Future<Uint8List?> loadAvatarBytes(String value) async {
  if (!value.startsWith('data:image/')) return null;
  final comma = value.indexOf(',');
  if (comma < 0) return null;
  try {
    return base64Decode(value.substring(comma + 1));
  } on FormatException {
    return null;
  }
}
