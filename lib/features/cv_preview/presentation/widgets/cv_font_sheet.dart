import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../cv_editor/domain/models/cv_font.dart';

/// Lets users pick the CV font. Pro fonts stay visible with a lock so Free
/// users know they exist; tapping one calls [onLocked].
class CvFontSheet extends StatelessWidget {
  const CvFontSheet({
    super.key,
    required this.currentFontId,
    required this.isPro,
    required this.isEnglish,
    required this.onSelected,
    required this.onLocked,
  });

  final String currentFontId;
  final bool isPro;
  final bool isEnglish;
  final ValueChanged<String> onSelected;
  final VoidCallback onLocked;

  static Future<void> show({
    required BuildContext context,
    required String currentFontId,
    required bool isPro,
    required bool isEnglish,
    required ValueChanged<String> onSelected,
    required VoidCallback onLocked,
  }) {
    return showAppSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CvFontSheet(
        currentFontId: currentFontId,
        isPro: isPro,
        isEnglish: isEnglish,
        onSelected: (id) {
          Navigator.of(ctx).pop();
          onSelected(id);
        },
        onLocked: () {
          Navigator.of(ctx).pop();
          onLocked();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = CvFontCatalog.byId(currentFontId).id;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSheetHandle(),
            const SizedBox(height: 16),
            Text(
              isEnglish ? 'Font' : 'Phông chữ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primarySlate,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isEnglish
                  ? 'Applies to the whole CV.'
                  : 'Áp dụng cho toàn bộ CV.',
              style: const TextStyle(color: AppTheme.mutedText),
            ),
            const SizedBox(height: 12),
            for (final font in CvFontCatalog.all)
              _FontTile(
                font: font,
                selected: font.id == current,
                locked: font.isPremium && !isPro,
                onTap: () =>
                    font.isPremium && !isPro ? onLocked() : onSelected(font.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _FontTile extends StatelessWidget {
  const _FontTile({
    required this.font,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final CvFont font;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppTheme.brandIndigo.withValues(alpha: 0.06)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppTheme.brandIndigo : AppTheme.softBorder,
          ),
        ),
        child: InkWell(
          key: ValueKey('cv-font-${font.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        font.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primarySlate,
                        ),
                      ),
                      Text(
                        font.description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (locked)
                  const _ProTag()
                else if (selected)
                  const Icon(
                    Icons.check_rounded,
                    color: AppTheme.brandIndigo,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProTag extends StatelessWidget {
  const _ProTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.brandIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 13,
            color: AppTheme.brandIndigo,
          ),
          SizedBox(width: 4),
          Text(
            'Pro',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.brandIndigo,
            ),
          ),
        ],
      ),
    );
  }
}
