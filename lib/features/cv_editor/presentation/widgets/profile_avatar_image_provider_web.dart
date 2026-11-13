import 'dart:convert';

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

  final uri = Uri.tryParse(value);
  if (uri == null || !const {'blob', 'https', 'http'}.contains(uri.scheme)) {
    return null;
  }
  return NetworkImage(value);
}
