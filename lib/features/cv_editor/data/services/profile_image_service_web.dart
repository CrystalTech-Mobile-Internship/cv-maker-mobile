import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import '../../domain/services/profile_image_service.dart';

ProfileImageService createProfileImageService() => WebProfileImageService();

final class WebProfileImageService implements ProfileImageService {
  WebProfileImageService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  static const _maximumAvatarBytes = 2 * 1024 * 1024;

  final ImagePicker _picker;

  @override
  Future<String?> pickAndStoreImage() async {
    final selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1000,
      maxHeight: 1000,
    );
    if (selected == null) return null;

    final bytes = await selected.readAsBytes();
    if (bytes.length > _maximumAvatarBytes) {
      throw const FormatException(
        'Ảnh sau khi tối ưu vẫn lớn hơn 2 MB. Hãy chọn ảnh nhỏ hơn.',
      );
    }

    final mimeType = _safeMimeType(selected.mimeType, selected.name);
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  static String _safeMimeType(String? mimeType, String fileName) {
    if (const {'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
      return mimeType!;
    }
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
