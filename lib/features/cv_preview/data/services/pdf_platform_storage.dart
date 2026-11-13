import 'dart:typed_data';

import 'pdf_platform_storage_native.dart'
    if (dart.library.js_interop) 'pdf_platform_storage_web.dart'
    as platform;

Future<String> savePdfBytes(Uint8List bytes, String fileName) =>
    platform.savePdfBytes(bytes, fileName);

Future<void> sharePdfBytes(Uint8List bytes, String fileName) =>
    platform.sharePdfBytes(bytes, fileName);

Future<Uint8List?> loadAvatarBytes(String value) =>
    platform.loadAvatarBytes(value);
