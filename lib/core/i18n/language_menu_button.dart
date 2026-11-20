import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'app_language.dart';

/// Small `VI` / `EN` switch for app bars and side menus.
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key, this.compact = true});

  /// Compact shows the code only; otherwise the full language name.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appLanguageProvider);
    return PopupMenuButton<AppLanguage>(
      key: const Key('language-menu'),
      tooltip: tr('Ngôn ngữ', 'Language'),
      initialValue: current,
      onSelected: (language) =>
          ref.read(appLanguageProvider.notifier).change(language),
      itemBuilder: (context) => [
        for (final language in AppLanguage.values)
          PopupMenuItem(
            key: Key('language-${language.code}'),
            value: language,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    language.code.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ),
                Expanded(child: Text(language.nativeName)),
                if (language == current)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppTheme.brandIndigo,
                  ),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.translate_rounded,
              size: 18,
              color: AppTheme.primarySlate,
            ),
            const SizedBox(width: 6),
            Text(
              compact ? current.code.toUpperCase() : current.nativeName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primarySlate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
