import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/profile_image_service.dart';
import 'profile_image_service_native.dart'
    if (dart.library.js_interop) 'profile_image_service_web.dart'
    as platform;

final profileImageServiceProvider = Provider<ProfileImageService>(
  (ref) => platform.createProfileImageService(),
);
