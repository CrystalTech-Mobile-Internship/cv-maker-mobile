import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/widgets/floating_launcher.dart';
import '../../admin/presentation/admin_providers.dart';

/// Floating button in the bottom-right corner that opens the support chat.
/// Admins answer support instead of writing to it, so they get a shortcut
/// to the admin inbox.
class SupportChatButton extends ConsumerWidget {
  const SupportChatButton({super.key, this.small = false});

  /// Secondary (white) look for stacking above the main floating button.
  final bool small;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;
    if (isAdmin) {
      return FloatingLauncher(
        key: const Key('admin-inbox-fab'),
        primary: !small,
        icon: const Icon(Icons.admin_panel_settings_outlined),
        label: tr('Quản trị', 'Admin'),
        onPressed: () => context.push('/admin'),
      );
    }
    return FloatingLauncher(
      key: const Key('support-chat-fab'),
      primary: !small,
      icon: const Icon(Icons.headset_mic_outlined),
      label: tr('Hỗ trợ', 'Support'),
      onPressed: () => context.push('/support'),
    );
  }
}
