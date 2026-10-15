import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/services/profile_image_service.dart';

final profileImageServiceProvider = Provider<ProfileImageService>(
  (ref) => ProfileImageServiceImpl(),
);

final class ProfileImageServiceImpl implements ProfileImageService {
  ProfileImageServiceImpl({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pickAndStoreImage() async {
    final selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (selected == null) return null;

    final documents = await getApplicationDocumentsDirectory();
    final avatarDirectory = Directory('${documents.path}/cv_avatars');
    await avatarDirectory.create(recursive: true);

    final extension = _safeExtension(selected.path);
    final destination = File(
      '${avatarDirectory.path}/avatar_${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    await File(selected.path).copy(destination.path);
    return destination.path;
  }

  static String _safeExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return '.jpg';
    final extension = path.substring(dot).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.webp'}.contains(extension)
        ? extension
        : '.jpg';
  }
}
