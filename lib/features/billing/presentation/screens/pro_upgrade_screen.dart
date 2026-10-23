import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class ProUpgradeScreen extends StatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  State<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends State<ProUpgradeScreen> {
  String _plan = 'lifetime';

  void _showPaymentPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Giao diện VietQR đã có. Cổng PayOS/SePay sẽ được kết nối sau.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLifetime = _plan == 'lifetime';
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                ),
                borderRadius: BorderRadius.circular(18),
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
                    'Mở khóa mẫu Premium, ATS không giới hạn, AI viết nội dung và PDF không watermark.',
                    style: TextStyle(color: Color(0xFFDBEAFE), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _ComparisonCard(),
            const SizedBox(height: 16),
            _PlanCard(
              selected: _plan == 'monthly',
              title: 'Theo tháng',
              price: '49.000đ',
              detail: 'Hủy bất cứ lúc nào',
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
                    'Quét VietQR để nâng cấp',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 180,
                    height: 180,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 84,
                          color: AppTheme.primaryNavy,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'QR minh họa',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isLifetime
                        ? 'Nội dung CK: CVPRO-LIFETIME'
                        : 'Nội dung CK: CVPRO-MONTHLY',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _showPaymentPlaceholder,
              style: AppTheme.createCvButton,
              icon: const Icon(Icons.verified_rounded),
              label: const Text('Tôi đã chuyển khoản'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thanh toán thật và mở khóa tài khoản Pro sẽ được xử lý ở bước sau.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Tạo CV trên máy', true, true),
      ('Xuất PDF A4', true, true),
      ('Tối đa 2 CV (Free)', true, false),
      ('Mẫu Premium', false, true),
      ('ATS & AI không giới hạn', false, true),
      ('PDF không watermark', false, true),
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
