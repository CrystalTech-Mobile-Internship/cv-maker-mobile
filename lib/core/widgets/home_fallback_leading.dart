import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../i18n/app_language.dart';

/// Back button for screens that may be opened directly (refresh or link):
/// when there is no page to go back to, it returns to [fallback].
Widget? homeFallbackLeading(BuildContext context, {String fallback = '/home'}) {
  if (Navigator.of(context).canPop()) return null;
  return IconButton(
    tooltip: tr('Quay lại', 'Back'),
    icon: const Icon(Icons.arrow_back),
    onPressed: () => context.go(fallback),
  );
}
