import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/app_language.dart';
import '../../../ai_tools/presentation/controllers/ai_assistant_providers.dart';
import '../../data/supabase_billing_repository.dart';
import '../../domain/billing_models.dart';

/// Current plan, pending upgrade request and today's AI usage.
class BillingStatusCard extends ConsumerWidget {
  const BillingStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(billingStatusProvider);
    final quota = ref.watch(aiQuotaProvider);

    String planLine(BillingStatus value) {
      if (!value.isPro) return tr('Gói hiện tại: Free', 'Current plan: Free');
      final until = value.proUntil;
      if (until == null) {
        return tr('Gói hiện tại: Pro trọn đời', 'Current plan: Lifetime Pro');
      }
      final local = until.toLocal();
      final date = '${local.day}/${local.month}/${local.year}';
      return tr('Gói hiện tại: Pro đến $date', 'Current plan: Pro until $date');
    }

    String? requestLine(BillingStatus value) {
      final request = value.latestRequest;
      if (request == null) return null;
      return switch (request.status) {
        ProRequestStatus.pending => tr(
          'Đang chờ thanh toán gói ${request.plan.label}.',
          'Waiting for payment for ${request.plan.label}.',
        ),
        ProRequestStatus.rejected => tr(
          'Thanh toán gần nhất chưa được xác nhận.',
          'Your last payment was not confirmed.',
        ),
        ProRequestStatus.approved || ProRequestStatus.expired => null,
      };
    }

    return Container(
      key: const ValueKey('billing-status-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: status.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, _) => Text(
          error is BillingFailure
              ? error.message
              : tr('Chưa tải được gói.', 'Could not load your plan.'),
          style: const TextStyle(color: AppTheme.mutedText),
        ),
        data: (value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planLine(value),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryNavy,
              ),
            ),
            if (quota != null) ...[
              const SizedBox(height: 4),
              Text(
                tr(
                  'Đã dùng hôm nay: ${quota.used}/${quota.limit} lượt',
                  'Used today: ${quota.used}/${quota.limit}',
                ),
                style: const TextStyle(color: AppTheme.mutedText),
              ),
            ],
            if (requestLine(value) != null) ...[
              const SizedBox(height: 6),
              Text(
                requestLine(value)!,
                style: const TextStyle(fontSize: 12.5, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
