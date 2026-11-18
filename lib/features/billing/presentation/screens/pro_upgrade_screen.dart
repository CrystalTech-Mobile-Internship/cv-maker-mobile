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
import '../../../../core/widgets/home_fallback_leading.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';

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
      appBar: AppBar(
        leading: homeFallbackLeading(context),
        title: const Text('Nâng cấp Pro'),
      ),
      body: WebConstrainedWidth(
        maxWidth: 760,
        child: SafeArea(
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
                      '200 lượt dùng tính năng AI mỗi ngày và mẫu CV cao cấp.',
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

  // (label, free, pro): `true`/`false` draws a mark, a String is shown as is.
  static const _basic = <(String, Object, Object)>[
    ('Tạo, sửa CV và lưu trên mọi thiết bị', true, true),
    ('Xuất CV ra PDF, Word', true, true),
    ('Mẫu CV cao cấp', false, true),
  ];

  static const _ai = <(String, Object, Object)>[
    ('Trò chuyện để tạo CV', true, true),
    ('Đọc CV từ file PDF, Word, ảnh', true, true),
    ('Viết lại tóm tắt và kinh nghiệm', true, true),
    ('Viết thư xin việc', true, true),
    ('Chấm điểm, chỉnh CV theo tin tuyển dụng', true, true),
    ('Luyện phỏng vấn và nhận góp ý', true, true),
    ('Lượt dùng mỗi ngày', '15', '200'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('pro-comparison'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ComparisonHeader('Tính năng'),
          const Divider(height: 20),
          for (final row in _basic) _ComparisonRow(row),
          const SizedBox(height: 6),
          const _ComparisonHeader('Tính năng AI'),
          const Divider(height: 20),
          for (final row in _ai) _ComparisonRow(row),
          const SizedBox(height: 4),
          const Text(
            'Mỗi lần dùng tốn 1 lượt; đọc CV từ file, viết thư xin việc tốn 2 lượt; tạo CV từ cuộc trò chuyện, chấm điểm theo tin tuyển dụng tốn 3 lượt. Lượt dùng được làm mới mỗi ngày.',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonHeader extends StatelessWidget {
  const _ComparisonHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.w800);
    return Row(
      children: [
        Expanded(child: Text(title, style: style)),
        const SizedBox(
          width: 52,
          child: Text('Free', textAlign: TextAlign.center, style: style),
        ),
        const SizedBox(
          width: 52,
          child: Text('Pro', textAlign: TextAlign.center, style: style),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow(this.row);

  final (String, Object, Object) row;

  Widget _cell(Object value, Color color) {
    if (value is String) {
      return Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w800, color: color),
      );
    }
    final on = value == true;
    return Icon(
      on ? Icons.check_circle : Icons.remove_circle_outline,
      color: on ? color : const Color(0xFF94A3B8),
      size: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(row.$1)),
          SizedBox(width: 52, child: _cell(row.$2, AppTheme.successGreen)),
          SizedBox(width: 52, child: _cell(row.$3, AppTheme.createAction)),
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
