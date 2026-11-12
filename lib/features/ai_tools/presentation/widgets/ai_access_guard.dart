import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../controllers/ai_assistant_providers.dart';

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
        title: const Text('Đăng nhập để dùng AI'),
        content: const Text(
          'Trợ lý AI cần tài khoản để bảo vệ dữ liệu và giới hạn lượt dùng. '
          'Tài khoản Free được tặng lượt AI miễn phí mỗi ngày.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng nhập'),
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
      title: const Text('Quyền riêng tư khi dùng AI'),
      content: const Text(
        '• Chỉ phần nội dung cần thiết (văn bản CV, câu trả lời của bạn) được '
        'gửi qua máy chủ bảo mật của ứng dụng tới mô hình AI.\n'
        '• Ứng dụng không lưu nội dung đó trên máy chủ và không ghi log.\n'
        '• Kết quả AI chỉ là gợi ý — bạn luôn xem lại trước khi lưu.\n'
        '• Không nhập mật khẩu, số CCCD hay thông tin tài chính vào trò chuyện.',
        style: TextStyle(height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Không đồng ý'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Đồng ý'),
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
    return '${failure.message} (Lượt AI được làm mới mỗi ngày.)';
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
      message:
          'Gói ${quota.isPro ? 'Pro' : 'Free'}: đã dùng ${quota.used}/${quota.limit} lượt hôm nay',
      child: Chip(
        key: const ValueKey('ai-quota-chip'),
        label: Text(
          'AI ${quota.remaining}/${quota.limit}',
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
