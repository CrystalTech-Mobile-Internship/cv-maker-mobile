import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/widgets/floating_launcher.dart';

/// Floating button in the bottom-right corner that opens the support chat.
class SupportChatButton extends StatelessWidget {
  const SupportChatButton({super.key, this.small = false});

  /// Secondary (white) look for stacking above the main floating button.
  final bool small;

  @override
  Widget build(BuildContext context) {
    return FloatingLauncher(
      key: const Key('support-chat-fab'),
      primary: !small,
      icon: const Icon(Icons.headset_mic_outlined),
      label: tr('Hỗ trợ', 'Support'),
      onPressed: () => context.push('/support'),
    );
  }
}
