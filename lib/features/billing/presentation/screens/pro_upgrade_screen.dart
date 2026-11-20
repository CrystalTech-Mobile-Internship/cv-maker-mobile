import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/app_language.dart';
import '../../../../core/widgets/home_fallback_leading.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../ai_tools/presentation/controllers/ai_assistant_providers.dart';
import '../../../auth/presentation/auth_redirect.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cv_editor/domain/models/cv_font.dart';
import '../../../cv_editor/domain/models/cv_template.dart';
import '../../data/supabase_billing_repository.dart';
import '../../domain/billing_models.dart';
import '../widgets/bank_transfer_box.dart';
import '../../../support/presentation/support_chat_button.dart';

class ProUpgradeScreen extends ConsumerStatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  ConsumerState<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends ConsumerState<ProUpgradeScreen> {
  ProPlan _plan = ProPlan.lifetime;
  ProUpgradeRequest? _checkout;
  bool _starting = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    if (ref.read(currentAuthUserProvider) != null) {
      ref.read(aiAssistantRepositoryProvider).fetchQuota().ignore();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _startCheckout() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final checkout = await ref
          .read(billingRepositoryProvider)
          .startCheckout(_plan);
      if (!mounted) return;
      setState(() => _checkout = checkout);
      _poll?.cancel();
      // The webhook upgrades the account; check every few seconds.
      _poll = Timer.periodic(
        const Duration(seconds: 4),
        (_) => ref.invalidate(billingStatusProvider),
      );
    } on BillingFailure catch (failure) {
      _toast(failure.message);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _selectPlan(ProPlan plan) {
    if (plan == _plan) return;
    _poll?.cancel();
    setState(() {
      _plan = plan;
      _checkout = null;
    });
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(currentAuthUserProvider);
    final status = authUser == null
        ? null
        : ref.watch(billingStatusProvider).valueOrNull;
    final isPro = status?.isPro ?? false;
    if (isPro) _poll?.cancel();

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      floatingActionButton: const SupportChatButton(),
      appBar: AppBar(
        leading: homeFallbackLeading(context),
        title: Text(tr('Nâng cấp Pro', 'Upgrade to Pro')),
      ),
      body: WebConstrainedWidth(
        maxWidth: 860,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              const _Header(),
              const SizedBox(height: 20),
              if (isPro)
                _ProActiveCard(status: status!)
              else ...[
                _PlanPicker(selected: _plan, onSelected: _selectPlan),
                const SizedBox(height: 16),
                if (authUser == null)
                  _LoginRequiredCard(
                    onLogin: () => context.push(
                      authEntryLocation('/login', '/upgrade-pro'),
                    ),
                    onRegister: () => context.push(
                      authEntryLocation('/register', '/upgrade-pro'),
                    ),
                  )
                else if (_checkout == null)
                  FilledButton(
                    key: const ValueKey('pro-start-checkout'),
                    onPressed: _starting ? null : _startCheckout,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandIndigo,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _starting
                          ? tr('Đang tạo mã...', 'Preparing...')
                          : tr(
                              'Thanh toán ${_plan.price}',
                              'Pay ${_plan.price}',
                            ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  _CheckoutCard(checkout: _checkout!),
              ],
              const SizedBox(height: 24),
              const _ComparisonCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Smart CV Pro',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr(
            'Thêm mẫu CV, phông chữ và lượt dùng AI để hoàn thiện CV nhanh hơn.',
            'More templates, fonts and AI uses to finish your CV faster.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.mutedText, height: 1.4),
        ),
      ],
    );
  }
}

class _PlanPicker extends StatelessWidget {
  const _PlanPicker({required this.selected, required this.onSelected});

  final ProPlan selected;
  final ValueChanged<ProPlan> onSelected;

  @override
  Widget build(BuildContext context) {
    final monthly = _PlanCard(
      key: const ValueKey('pro-plan-monthly'),
      plan: ProPlan.monthly,
      selected: selected == ProPlan.monthly,
      period: tr('/ 30 ngày', '/ 30 days'),
      note: tr('Dùng ngắn hạn khi đang tìm việc', 'For a short job search'),
      onTap: () => onSelected(ProPlan.monthly),
    );
    final lifetime = _PlanCard(
      key: const ValueKey('pro-plan-lifetime'),
      plan: ProPlan.lifetime,
      selected: selected == ProPlan.lifetime,
      period: tr('một lần', 'one time'),
      note: tr('Trả một lần, dùng mãi', 'Pay once, keep it'),
      badge: tr('Tiết kiệm nhất', 'Best value'),
      onTap: () => onSelected(ProPlan.lifetime),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [lifetime, const SizedBox(height: 12), monthly],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: monthly),
              const SizedBox(width: 12),
              Expanded(child: lifetime),
            ],
          ),
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.period,
    required this.note,
    required this.onTap,
    this.badge,
  });

  final ProPlan plan;
  final bool selected;
  final String period;
  final String note;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.brandIndigo : AppTheme.softBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    plan.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primarySlate,
                    ),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.brandIndigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.brandIndigo,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                    color: selected ? AppTheme.brandIndigo : AppTheme.mutedText,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    plan.price,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    period,
                    style: const TextStyle(color: AppTheme.mutedText),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                note,
                style: const TextStyle(color: AppTheme.mutedText, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({required this.checkout});

  final ProUpgradeRequest checkout;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('pro-checkout'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('Quét mã bằng ứng dụng ngân hàng', 'Scan with your banking app'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Mã QR đã điền sẵn số tiền và nội dung. Giữ nguyên nội dung khi chuyển.',
              'The QR code fills in the amount and note. Keep the note as is.',
            ),
            style: const TextStyle(color: AppTheme.mutedText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          BankTransferBox(
            amount: checkout.amountDue,
            transferCode: checkout.transferCode,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(
                      'Đang chờ thanh toán. Tài khoản sẽ tự nâng cấp ngay khi nhận được tiền.',
                      'Waiting for payment. Your account upgrades as soon as it arrives.',
                    ),
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProActiveCard extends StatelessWidget {
  const _ProActiveCard({required this.status});

  final BillingStatus status;

  @override
  Widget build(BuildContext context) {
    final until = status.proUntil?.toLocal();
    return Container(
      key: const ValueKey('pro-active'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successGreen),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppTheme.successGreen,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Bạn đang dùng Pro', 'You are on Pro'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  until == null
                      ? tr('Trọn đời', 'Lifetime')
                      : tr(
                          'Đến ngày ${until.day}/${until.month}/${until.year}',
                          'Until ${until.day}/${until.month}/${until.year}',
                        ),
                  style: const TextStyle(color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginRequiredCard extends StatelessWidget {
  const _LoginRequiredCard({required this.onLogin, required this.onRegister});

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(
        children: [
          Text(
            tr('Đăng nhập để nâng cấp', 'Sign in to upgrade'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Gói Pro gắn với tài khoản, dùng được trên web và điện thoại.',
              'Pro is tied to your account and works on web and phone.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.mutedText, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onLogin,
              child: Text(tr('Đăng nhập', 'Sign in')),
            ),
          ),
          TextButton(
            onPressed: onRegister,
            child: Text(
              tr('Chưa có tài khoản? Đăng ký', 'No account yet? Sign up'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard();

  @override
  Widget build(BuildContext context) {
    final rows = <(String, Object, Object)>[
      (
        tr('Mẫu CV', 'CV templates'),
        '${CvTemplateCatalog.freeTemplates.length}',
        '${CvTemplateCatalog.allTemplates.length}',
      ),
      (
        tr('Phông chữ', 'Fonts'),
        '${CvFontCatalog.all.where((f) => !f.isPremium).length}',
        '${CvFontCatalog.all.length}',
      ),
      (tr('Lượt dùng AI mỗi ngày', 'AI uses per day'), '15', '200'),
      (tr('Tải PDF và Word', 'PDF and Word download'), true, true),
      (
        tr('Lưu và đồng bộ trên mọi thiết bị', 'Sync across devices'),
        true,
        true,
      ),
    ];
    return Container(
      key: const Key('pro-comparison'),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(
        children: [
          _ComparisonLine(
            label: tr('So sánh gói', 'Compare plans'),
            free: 'Free',
            pro: 'Pro',
            header: true,
          ),
          for (final row in rows)
            _ComparisonLine(label: row.$1, free: row.$2, pro: row.$3),
        ],
      ),
    );
  }
}

class _ComparisonLine extends StatelessWidget {
  const _ComparisonLine({
    required this.label,
    required this.free,
    required this.pro,
    this.header = false,
  });

  final String label;
  final Object free;
  final Object pro;
  final bool header;

  Widget _cell(Object value, {required bool highlight}) {
    if (value is bool) {
      return Icon(
        value ? Icons.check_rounded : Icons.remove_rounded,
        size: 20,
        color: value
            ? (highlight ? AppTheme.brandIndigo : AppTheme.primarySlate)
            : AppTheme.mutedText,
      );
    }
    return Text(
      '$value',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: highlight ? AppTheme.brandIndigo : AppTheme.primarySlate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: header
          ? null
          : const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.softBorder)),
            ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: header ? FontWeight.w800 : FontWeight.w500,
                color: AppTheme.primaryNavy,
              ),
            ),
          ),
          SizedBox(width: 64, child: _cell(free, highlight: false)),
          SizedBox(width: 64, child: _cell(pro, highlight: true)),
        ],
      ),
    );
  }
}
