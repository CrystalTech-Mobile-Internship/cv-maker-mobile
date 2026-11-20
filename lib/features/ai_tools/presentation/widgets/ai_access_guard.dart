import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../controllers/ai_assistant_providers.dart';
import '../../../../core/i18n/app_language.dart';

/// Ensures a signed-in user who accepted the AI data notice. Returns false
/// (after explaining why) when the AI call must not happen.
Future<bool> ensureAiAccess(
  BuildContext context,
  WidgetRef ref, {
  String redirectPath = '/home',
}) async {
  if (ref.read(currentAuthUserProvider) == null) {
    final login = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_person_rounded),
        title: Text(tr('Cần đăng nhập', 'Sign in needed')),
        content: Text(
          tr(
            'Tài khoản miễn phí có 15 lượt dùng mỗi ngày.',
            'Free accounts get 15 uses a day.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Để sau', 'Later')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Đăng nhập', 'Sign in')),
          ),
        ],
      ),
    );
    if (login == true && context.mounted) {
      context.push('/login?redirect=${Uri.encodeComponent(redirectPath)}');
    }
    return false;
  }

  final consent = ref.read(aiConsentServiceProvider);
  if (await consent.hasConsented()) return true;
  if (!context.mounted) return false;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.privacy_tip_outlined),
      title: Text(tr('Quyền riêng tư', 'Privacy')),
      content: Text(
        tr(
          'Nội dung bạn nhập được gửi đi để xử lý và không được lưu lại. '
              'Đừng nhập mật khẩu hay số giấy tờ tùy thân.',
          'What you type is sent for processing and is not stored. Do not enter passwords or ID numbers.',
        ),
        style: TextStyle(height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr('Không đồng ý', 'Decline')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(tr('Đồng ý', 'Agree')),
        ),
      ],
    ),
  );
  if (accepted == true) {
    await consent.recordConsent();
    return true;
  }
  return false;
}

/// Runs [task] behind a blocking progress dialog.
Future<T> runWithAiProgress<T>(
  BuildContext context,
  String message,
  Future<T> Function() task,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}

/// Human-friendly explanation of an AI failure, with an upgrade hint when
/// the Free budget is exhausted.
String describeAiFailure(AiWritingFailure failure) {
  if (failure.code == AiWritingFailureCode.quotaExceeded) {
    return failure.message;
  }
  return failure.message;
}

/// Small chip showing today's remaining AI credits.
class AiQuotaChip extends ConsumerWidget {
  const AiQuotaChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AiQuota? quota = ref.watch(aiQuotaProvider);
    if (quota == null) return const SizedBox.shrink();
    final low = quota.remaining <= 2;
    return Tooltip(
      message: tr(
        'Gói ${quota.isPro ? 'Pro' : 'Free'}: đã dùng ${quota.used}/${quota.limit} lượt hôm nay',
        '${quota.isPro ? 'Pro' : 'Free'} plan: ${quota.used}/${quota.limit} uses today',
      ),
      child: Chip(
        key: const ValueKey('ai-quota-chip'),
        label: Text(
          tr(
            '${quota.remaining}/${quota.limit} lượt',
            '${quota.remaining}/${quota.limit} uses',
          ),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: low ? AppTheme.dangerRose : AppTheme.brandIndigo,
          ),
        ),
        visualDensity: VisualDensity.compact,
        side: BorderSide.none,
        backgroundColor: AppTheme.indigoSurface,
      ),
    );
  }
}
