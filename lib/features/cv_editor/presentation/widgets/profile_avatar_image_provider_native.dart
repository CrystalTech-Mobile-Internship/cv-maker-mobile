import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider<Object>? profileAvatarImageProvider(String value) {
  if (value.startsWith('data:image/')) {
    final comma = value.indexOf(',');
    if (comma < 0) return null;
    try {
      return MemoryImage(base64Decode(value.substring(comma + 1)));
    } on FormatException {
      return null;
    }
  }

  final file = File(value);
  return file.existsSync() ? FileImage(file) : null;
}
