import 'package:flutter/widgets.dart';

import 'profile_avatar_image_provider_native.dart'
    if (dart.library.js_interop) 'profile_avatar_image_provider_web.dart'
    as platform;

ImageProvider<Object>? profileAvatarImageProvider(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return platform.profileAvatarImageProvider(value);
}
