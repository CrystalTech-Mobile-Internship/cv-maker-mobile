import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/widgets/desktop_frame_scope.dart';
import '../../../core/widgets/home_fallback_leading.dart';
import '../../billing/domain/billing_models.dart';
import 'admin_providers.dart';
import 'widgets/admin_payments_tab.dart';
import 'widgets/admin_support_tab.dart';

/// Admin page: support inbox and Pro payments. Only accounts listed in
/// `admin_users` see data; the server refuses everyone else.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key, this.section = AdminSection.support});

  final AdminSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    return isAdmin.when(
      loading: () => Scaffold(
        appBar: AppBar(
          leading: homeFallbackLeading(context),
          title: Text(tr('Quản trị', 'Admin')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const _NotAllowed(),
      data: (allowed) =>
          allowed ? _AdminBody(section: section) : const _NotAllowed(),
    );
  }
}

class _NotAllowed extends StatelessWidget {
  const _NotAllowed();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        leading: homeFallbackLeading(context),
        title: Text(tr('Quản trị', 'Admin')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            tr(
              'Trang này chỉ dành cho quản trị viên.',
              'This page is for admins only.',
            ),
            key: const Key('admin-not-allowed'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.mutedText),
          ),
        ),
      ),
    );
  }
}

/// Which admin page is open. On computers each one has its own sidebar
/// entry; phones switch between them with tabs.
enum AdminSection { support, payments }

class _AdminBody extends ConsumerWidget {
  const _AdminBody({required this.section});

  final AdminSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refresh = IconButton(
      key: const Key('admin-refresh'),
      tooltip: tr('Tải lại', 'Refresh'),
      onPressed: () {
        ref.invalidate(adminStatsProvider);
        ref.invalidate(adminThreadsProvider);
        ref.invalidate(adminProRequestsProvider);
        ref.invalidate(adminPaymentEventsProvider);
      },
      icon: const Icon(Icons.refresh_rounded),
    );

    if (DesktopFrameScope.of(context)) {
      final isSupport = section == AdminSection.support;
      return Scaffold(
        backgroundColor: AppTheme.surfaceLight,
        appBar: AppBar(
          title: Text(
            isSupport
                ? tr('Hỗ trợ người dùng', 'User support')
                : tr('Thanh toán', 'Payments'),
          ),
          actions: [refresh, const SizedBox(width: 4)],
        ),
        body: Column(
          children: [
            _StatsBar(section: section),
            const Divider(height: 1),
            Expanded(
              child: isSupport
                  ? const AdminSupportTab()
                  : const AdminPaymentsTab(),
            ),
          ],
        ),
      );
    }

    final stats = ref.watch(adminStatsProvider).valueOrNull;
    final waiting = stats?.waitingThreads ?? 0;
    final pending = stats?.pendingRequests ?? 0;
    return DefaultTabController(
      length: 2,
      initialIndex: section.index,
      child: Scaffold(
        backgroundColor: AppTheme.surfaceLight,
        appBar: AppBar(
          leading: homeFallbackLeading(context),
          title: Text(tr('Quản trị', 'Admin')),
          actions: [refresh, const SizedBox(width: 4)],
          bottom: TabBar(
            labelColor: AppTheme.brandIndigo,
            unselectedLabelColor: AppTheme.mutedText,
            indicatorColor: AppTheme.brandIndigo,
            tabs: [
              Tab(
                key: const Key('admin-tab-support'),
                text: waiting > 0
                    ? tr('Hỗ trợ ($waiting)', 'Support ($waiting)')
                    : tr('Hỗ trợ', 'Support'),
              ),
              Tab(
                key: const Key('admin-tab-payments'),
                text: pending > 0
                    ? tr('Thanh toán ($pending)', 'Payments ($pending)')
                    : tr('Thanh toán', 'Payments'),
              ),
            ],
          ),
        ),
        body: const Column(
          children: [
            _StatsBar(),
            Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [AdminSupportTab(), AdminPaymentsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBar extends ConsumerWidget {
  const _StatsBar({this.section});

  /// Shows only the numbers for this page; null shows them all.
  final AdminSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    final value = stats.valueOrNull;
    String show(int? number) => number == null ? '–' : '$number';
    return Container(
      width: double.infinity,
      color: AppTheme.surfaceCard,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (section != AdminSection.payments)
            _Stat(label: tr('Người dùng', 'Users'), value: show(value?.users)),
          if (section != AdminSection.support) ...[
            _Stat(
              label: tr('Đang dùng Pro', 'Pro now'),
              value: show(value?.proUsers),
            ),
            _Stat(
              label: tr('Doanh thu tháng này', 'Revenue this month'),
              value: value == null ? '–' : formatVnd(value.monthRevenue),
            ),
          ],
          if (section == AdminSection.payments)
            _Stat(
              label: tr('Chờ thanh toán', 'Awaiting payment'),
              value: show(value?.pendingRequests),
              highlight: (value?.pendingRequests ?? 0) > 0,
            ),
          if (section != AdminSection.payments)
            _Stat(
              label: tr('Chờ trả lời', 'Awaiting reply'),
              value: show(value?.waitingThreads),
              highlight: (value?.waitingThreads ?? 0) > 0,
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.amberSurface : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: highlight ? AppTheme.warningAmber : AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }
}
