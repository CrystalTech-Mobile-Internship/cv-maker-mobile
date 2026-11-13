import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/presentation/widgets/editor_typography_toolbar.dart';

/// Modal sheet for selecting CV primary color theme directly from the Preview Screen.
class CvPreviewColorSheet extends StatelessWidget {
  const CvPreviewColorSheet({
    super.key,
    required this.currentColor,
    required this.isEnglish,
    required this.onColorSelected,
  });

  final String currentColor;
  final bool isEnglish;
  final ValueChanged<String> onColorSelected;

  static Future<void> show({
    required BuildContext context,
    required String currentColor,
    required bool isEnglish,
    required ValueChanged<String> onColorSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CvPreviewColorSheet(
        currentColor: currentColor,
        isEnglish: isEnglish,
        onColorSelected: (hex) {
          onColorSelected(hex);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Color _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final presets = EditorTypographyToolbar.colorPresets;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandIndigo.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: AppTheme.brandIndigo,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnglish ? 'CV Color Theme' : 'Bảng màu chủ đạo CV',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isEnglish
                          ? 'Select accent color for headers, dates, and bullets'
                          : 'Đổi màu tiêu đề, đường kẻ và điểm nhấn trên bản A4',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Color Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: presets.map((preset) {
              final hex = preset['hex']!;
              final color = _parseHex(hex);
              final isSelected =
                  currentColor.toUpperCase() == hex.toUpperCase();
              final name = isEnglish ? preset['nameEn']! : preset['nameVi']!;

              return InkWell(
                key: ValueKey('preview-color-$hex'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => onColorSelected(hex),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 64) / 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withAlpha(20)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(30),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected ? color : AppTheme.primarySlate,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
