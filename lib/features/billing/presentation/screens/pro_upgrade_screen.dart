import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../auth/presentation/auth_redirect.dart';
import '../../../ai_tools/presentation/controllers/ai_assistant_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/supabase_billing_repository.dart';
import '../../domain/billing_models.dart';
import '../widgets/bank_transfer_box.dart';
import '../widgets/billing_status_card.dart';
import '../../../../core/constants/env_constants.dart';

class ProUpgradeScreen extends ConsumerStatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  ConsumerState<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends ConsumerState<ProUpgradeScreen> {
  String _plan = 'lifetime';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Show today's AI usage even before the first AI call of the session.
    if (ref.read(currentAuthUserProvider) != null) {
      ref.read(aiAssistantRepositoryProvider).fetchQuota().ignore();
    }
  }

  Future<void> _submitRequest() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(billingRepositoryProvider)
          .submitRequest(ProPlan.fromValue(_plan));
      ref.invalidate(billingStatusProvider);
      _toast(
        'Đã gửi yêu cầu. Tài khoản sẽ được nâng cấp khi nhận được chuyển khoản.',
      );
    } on BillingFailure catch (failure) {
      _toast(failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLifetime = _plan == 'lifetime';
    final authUser = ref.watch(currentAuthUserProvider);
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(title: const Text('Nâng cấp Pro')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart CV Maker Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Mẫu CV cao cấp và 200 lượt dùng mỗi ngày.',
                    style: TextStyle(color: Color(0xFFDBEAFE), height: 1.4),
                  ),
                ],
              ),
            ),
            if (authUser != null) ...[
              const SizedBox(height: 16),
              const BillingStatusCard(),
            ],
            const SizedBox(height: 16),
            const _ComparisonCard(),
            const SizedBox(height: 16),
            _PlanCard(
              selected: _plan == 'monthly',
              title: 'Theo tháng',
              price: '49.000đ',
              detail: 'Dùng trong 30 ngày',
              onTap: () => setState(() => _plan = 'monthly'),
            ),
            const SizedBox(height: 10),
            _PlanCard(
              selected: isLifetime,
              title: 'Trọn đời',
              price: '99.000đ',
              detail: 'Thanh toán một lần • Tiết kiệm hơn',
              badge: 'Khuyên dùng',
              onTap: () => setState(() => _plan = 'lifetime'),
            ),
            const SizedBox(height: 18),
            if (authUser == null)
              _LoginRequiredCard(
                onLogin: () =>
                    context.push(authEntryLocation('/login', '/upgrade-pro')),
                onRegister: () => context.push(
                  authEntryLocation('/register', '/upgrade-pro'),
                ),
              )
            else
              _AuthenticatedPaymentSection(
                isLifetime: isLifetime,
                accountEmail: authUser.email,
                transferCode: proTransferCode(
                  authUser.id,
                  ProPlan.fromValue(_plan),
                ),
                hasPendingRequest:
                    ref
                        .watch(billingStatusProvider)
                        .valueOrNull
                        ?.hasPendingRequest ??
                    false,
                isSubmitting: _submitting,
                onConfirm: _submitRequest,
              ),
          ],
        ),
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
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_circle_outlined,
            size: 38,
            color: AppTheme.primarySlate,
          ),
          const SizedBox(height: 10),
          const Text(
            'Đăng nhập để nâng cấp',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gói Pro gắn với tài khoản để dùng trên mọi thiết bị.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.mutedText, height: 1.35),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onLogin,
              child: const Text('Đăng nhập'),
            ),
          ),
          TextButton(
            onPressed: onRegister,
            child: const Text('Chưa có tài khoản? Đăng ký'),
          ),
        ],
      ),
    );
  }
}

class _AuthenticatedPaymentSection extends StatelessWidget {
  const _AuthenticatedPaymentSection({
    required this.isLifetime,
    required this.accountEmail,
    required this.transferCode,
    required this.hasPendingRequest,
    required this.isSubmitting,
    required this.onConfirm,
  });

  final bool isLifetime;
  final String accountEmail;
  final String transferCode;
  final bool hasPendingRequest;
  final bool isSubmitting;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              const Text(
                'Quét mã để chuyển khoản',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                accountEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 12),
              BankTransferBox(
                amount: isLifetime ? 99000 : 49000,
                transferCode: transferCode,
              ),
              const SizedBox(height: 10),
              SelectableText(
                'Nội dung CK: $transferCode',
                key: const ValueKey('pro-transfer-code'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ghi đúng nội dung để hệ thống nhận ra tài khoản của bạn.',
                style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('pro-confirm-transfer'),
          onPressed:
              hasPendingRequest ||
                  isSubmitting ||
                  EnvConstants.paymentAccount == null
              ? null
              : onConfirm,
          style: AppTheme.createCvButton,
          icon: const Icon(Icons.verified_outlined),
          label: Text(
            hasPendingRequest
                ? 'Đang chờ xác nhận chuyển khoản'
                : isSubmitting
                ? 'Đang gửi...'
                : 'Tôi đã chuyển khoản',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tài khoản được nâng lên Pro ngay khi nhận được chuyển khoản.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedText,
          ),
        ),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Tạo và xuất CV PDF, Word', true, true),
      ('Chấm điểm CV theo tin tuyển dụng', true, true),
      ('15 lượt dùng mỗi ngày', true, true),
      ('200 lượt dùng mỗi ngày', false, true),
      ('Mẫu CV cao cấp', false, true),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Tính năng',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  'Free',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  'Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1)),
                  SizedBox(
                    width: 48,
                    child: Icon(
                      row.$2 ? Icons.check_circle : Icons.remove_circle_outline,
                      color: row.$2
                          ? AppTheme.successGreen
                          : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Icon(
                      row.$3 ? Icons.check_circle : Icons.remove_circle_outline,
                      color: row.$3
                          ? AppTheme.createAction
                          : const Color(0xFF94A3B8),
                      size: 20,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.selected,
    required this.title,
    required this.price,
    required this.detail,
    required this.onTap,
    this.badge,
  });

  final bool selected;
  final String title;
  final String price;
  final String detail;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFECFDF5) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.createAction : const Color(0xFFE2E8F0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppTheme.createAction : AppTheme.mutedText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.createActionDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
