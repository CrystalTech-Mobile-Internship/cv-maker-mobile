import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/app_language.dart';
import '../../../billing/domain/billing_models.dart';
import '../../data/supabase_admin_repository.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';
import 'admin_format.dart';

/// Pro requests (approve by hand when the transfer note was wrong) and the
/// bank transfers SePay reported.
class AdminPaymentsTab extends ConsumerWidget {
  const AdminPaymentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(adminProRequestsProvider);
    final events = ref.watch(adminPaymentEventsProvider);
    return ListView(
      key: const Key('admin-payments'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(
                  tr('Chuyển khoản nhận được', 'Transfers received'),
                  tr(
                    '"Không khớp" là tiền đã vào nhưng sai nội dung hoặc thiếu tiền. Đối chiếu rồi duyệt yêu cầu tương ứng bên dưới.',
                    '"Not matched" means money arrived with a wrong note or amount. Check it, then approve the matching request below.',
                  ),
                ),
                _Card(
                  child: events.when(
                    loading: () => const _Loading(),
                    error: (error, _) => _Note(_errorText(error)),
                    data: (items) => items.isEmpty
                        ? _Note(
                            tr(
                              'Chưa có chuyển khoản nào.',
                              'No transfers yet.',
                            ),
                          )
                        : Column(
                            children: [
                              for (var i = 0; i < items.length; i++) ...[
                                if (i > 0) const Divider(height: 1),
                                _EventRow(items[i]),
                              ],
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  tr('Yêu cầu nâng cấp Pro', 'Pro requests'),
                  tr(
                    'Yêu cầu chờ thanh toán đứng đầu. Chỉ duyệt khi đã thấy tiền vào tài khoản.',
                    'Waiting requests come first. Approve only after the money has arrived.',
                  ),
                ),
                _Card(
                  child: requests.when(
                    loading: () => const _Loading(),
                    error: (error, _) => _Note(_errorText(error)),
                    data: (items) => items.isEmpty
                        ? _Note(tr('Chưa có yêu cầu nào.', 'No requests yet.'))
                        : Column(
                            children: [
                              for (var i = 0; i < items.length; i++) ...[
                                if (i > 0) const Divider(height: 1),
                                _RequestRow(items[i]),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _errorText(Object error) => error is AdminFailure
    ? error.message
    : tr('Chưa tải được dữ liệu.', 'Could not load data.');

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.caption);

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: LinearProgressIndicator(),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(text, style: const TextStyle(color: AppTheme.mutedText)),
  );
}

enum _Tone { good, warn, neutral, bad }

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.tone);

  final String label;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      _Tone.good => (AppTheme.tealSurface, AppTheme.successGreen),
      _Tone.warn => (AppTheme.amberSurface, AppTheme.warningAmber),
      _Tone.bad => (
        AppTheme.dangerRose.withValues(alpha: 0.08),
        AppTheme.dangerRose,
      ),
      _Tone.neutral => (AppTheme.surfaceLight, AppTheme.mutedText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow(this.event);

  final AdminPaymentEvent event;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (event.status) {
      'matched' => (tr('Đã bật Pro', 'Pro activated'), _Tone.good),
      'unmatched' => (tr('Không khớp', 'Not matched'), _Tone.warn),
      'ignored' => (tr('Bỏ qua', 'Ignored'), _Tone.neutral),
      _ => (tr('Đang xử lý', 'Processing'), _Tone.neutral),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatVnd(event.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  event.content.isEmpty
                      ? tr('(không có nội dung)', '(no note)')
                      : event.content,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 2),
                Text(
                  adminStamp(event.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusChip(label, tone),
        ],
      ),
    );
  }
}

class _RequestRow extends ConsumerStatefulWidget {
  const _RequestRow(this.request);

  final AdminProRequest request;

  @override
  ConsumerState<_RequestRow> createState() => _RequestRowState();
}

class _RequestRowState extends ConsumerState<_RequestRow> {
  bool _busy = false;

  Future<void> _review({required bool approve}) async {
    final request = widget.request;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          approve
              ? tr('Duyệt yêu cầu này?', 'Approve this request?')
              : tr('Từ chối yêu cầu này?', 'Reject this request?'),
        ),
        content: Text(
          approve
              ? tr(
                  'Tài khoản ${request.email} sẽ được bật Pro ngay. Chỉ duyệt khi đã thấy ${formatVnd(request.amount)} vào tài khoản.',
                  '${request.email} gets Pro right away. Approve only after ${formatVnd(request.amount)} has arrived.',
                )
              : tr(
                  'Yêu cầu sẽ bị đóng. Người dùng có thể tạo yêu cầu mới.',
                  'The request is closed. The user can start a new one.',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('Hủy', 'Cancel')),
          ),
          FilledButton(
            key: const Key('admin-review-confirm'),
            style: approve
                ? null
                : FilledButton.styleFrom(backgroundColor: AppTheme.dangerRose),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              approve ? tr('Duyệt', 'Approve') : tr('Từ chối', 'Reject'),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(adminRepositoryProvider)
          .reviewProRequest(request.id, approve: approve);
      ref
        ..invalidate(adminProRequestsProvider)
        ..invalidate(adminStatsProvider);
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            approve
                ? tr('Đã bật Pro cho tài khoản.', 'Pro is now active.')
                : tr('Đã từ chối yêu cầu.', 'Request rejected.'),
          ),
        ),
      );
    } on AdminFailure catch (failure) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(failure.message),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final plan = ProPlan.fromValue(request.plan);
    final planLabel = request.plan == 'lifetime'
        ? tr('Trọn đời', 'Lifetime')
        : plan == ProPlan.quarterly
        ? tr('3 tháng', '3 months')
        : tr('1 tháng', '1 month');
    final (label, tone) = switch (request.status) {
      'pending' => (tr('Chờ thanh toán', 'Awaiting payment'), _Tone.warn),
      'approved' => (tr('Đã duyệt', 'Approved'), _Tone.good),
      'rejected' => (tr('Từ chối', 'Rejected'), _Tone.bad),
      _ => (tr('Hết hạn', 'Expired'), _Tone.neutral),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.email.isEmpty
                          ? tr('(tài khoản đã xóa)', '(deleted account)')
                          : request.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$planLabel · ${formatVnd(request.amount)} · ${adminStamp(request.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      request.transferCode,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(label, tone),
            ],
          ),
          if (request.isPending) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: Key('admin-approve-${request.id}'),
                  onPressed: _busy ? null : () => _review(approve: true),
                  child: Text(tr('Duyệt', 'Approve')),
                ),
                OutlinedButton(
                  key: Key('admin-reject-${request.id}'),
                  onPressed: _busy ? null : () => _review(approve: false),
                  child: Text(tr('Từ chối', 'Reject')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
