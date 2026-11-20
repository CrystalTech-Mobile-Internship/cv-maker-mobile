import '../../../../core/i18n/app_language.dart';

/// A font bundled with the app for CV export. Every font here covers
/// Vietnamese and ships as an asset, so PDFs render the same offline.
final class CvFont {
  const CvFont({
    required this.id,
    required this.name,
    required String description,
    required this.regularAsset,
    required this.boldAsset,
    this.isPremium = false,
  }) : _description = description;

  final String id;
  final String name;
  final String _description;

  /// Short look-and-feel note, in the app language.
  String get description =>
      tr(_description, _fontEn[_description] ?? _description);
  final String regularAsset;
  final String boldAsset;
  final bool isPremium;
}

abstract final class CvFontCatalog {
  static const defaultId = 'roboto';

  static const all = <CvFont>[
    CvFont(
      id: 'roboto',
      name: 'Roboto',
      description: 'Rõ ràng, dễ đọc',
      regularAsset: 'assets/fonts/Roboto-Regular.ttf',
      boldAsset: 'assets/fonts/Roboto-Bold.ttf',
    ),
    CvFont(
      id: 'inter',
      name: 'Inter',
      description: 'Gọn, hiện đại',
      regularAsset: 'assets/fonts/Inter-Regular.ttf',
      boldAsset: 'assets/fonts/Inter-Bold.ttf',
    ),
    CvFont(
      id: 'lora',
      name: 'Lora',
      description: 'Có chân, trang trọng',
      regularAsset: 'assets/fonts/Lora-Regular.ttf',
      boldAsset: 'assets/fonts/Lora-Bold.ttf',
    ),
    CvFont(
      id: 'be_vietnam_pro',
      name: 'Be Vietnam Pro',
      description: 'Mềm mại, thân thiện',
      regularAsset: 'assets/fonts/BeVietnamPro-Regular.ttf',
      boldAsset: 'assets/fonts/BeVietnamPro-Bold.ttf',
      isPremium: true,
    ),
    CvFont(
      id: 'montserrat',
      name: 'Montserrat',
      description: 'Đậm nét, nổi bật',
      regularAsset: 'assets/fonts/Montserrat-Regular.ttf',
      boldAsset: 'assets/fonts/Montserrat-Bold.ttf',
      isPremium: true,
    ),
    CvFont(
      id: 'merriweather',
      name: 'Merriweather',
      description: 'Cổ điển, học thuật',
      regularAsset: 'assets/fonts/Merriweather-Regular.ttf',
      boldAsset: 'assets/fonts/Merriweather-Bold.ttf',
      isPremium: true,
    ),
  ];

  /// Unknown ids fall back to the default font instead of failing export.
  static CvFont byId(String? id) =>
      all.firstWhere((font) => font.id == id, orElse: () => all.first);

  static bool canUse(String id, {required bool isPro}) =>
      isPro || !byId(id).isPremium;
}

const _fontEn = <String, String>{
  'Rõ ràng, dễ đọc': 'Clear and easy to read',
  'Gọn, hiện đại': 'Compact and modern',
  'Có chân, trang trọng': 'Serif, formal',
  'Mềm mại, thân thiện': 'Soft and friendly',
  'Đậm nét, nổi bật': 'Bold and striking',
  'Cổ điển, học thuật': 'Classic, academic',
};
