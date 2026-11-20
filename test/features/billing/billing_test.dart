import 'package:cv_maker_mobile/features/ai_tools/domain/models/ai_assistant_models.dart';
import 'package:cv_maker_mobile/features/ai_tools/presentation/controllers/ai_assistant_providers.dart';
import 'package:cv_maker_mobile/features/billing/data/supabase_billing_repository.dart';
import 'package:cv_maker_mobile/features/billing/domain/billing_models.dart';
import 'package:cv_maker_mobile/features/billing/presentation/widgets/billing_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBilling implements BillingRepository {
  _FakeBilling(this.status);

  final BillingStatus status;

  @override
  Future<BillingStatus> fetchStatus() async => status;

  @override
  Future<ProUpgradeRequest> startCheckout(ProPlan plan) =>
      throw UnimplementedError();
}

void main() {
  test('formats prices in VND', () {
    expect(formatVnd(99000), '99.000đ');
    expect(formatVnd(1490000), '1.490.000đ');
    expect(ProPlan.monthly.price, '49.000đ');
    expect(ProPlan.quarterly.price, '119.000đ');
    expect(ProPlan.quarterly.monthlyAmount, 39600);
    expect(ProPlan.fromValue('quarterly'), ProPlan.quarterly);
  });

  test('maps request rows', () {
    final request = SupabaseBillingRepository.mapRequest({
      'id': 'r1',
      'plan': 'monthly',
      'transfer_code': 'CVPROMABCD1234',
      'status': 'pending',
      'created_at': '2026-11-12T00:00:00Z',
      'amount': 49000,
    });
    expect(request.plan, ProPlan.monthly);
    expect(request.amountDue, 49000);
    expect(request.status, ProRequestStatus.pending);
  });

  testWidgets('shows plan, pending request and AI usage', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billingRepositoryProvider.overrideWithValue(
            _FakeBilling(
              BillingStatus(
                isPro: false,
                latestRequest: ProUpgradeRequest(
                  id: 'r1',
                  plan: ProPlan.quarterly,
                  transferCode: 'CVPRO-LIFETIME-ABCD1234',
                  status: ProRequestStatus.pending,
                  createdAt: DateTime.utc(2026, 11, 12),
                ),
              ),
            ),
          ),
          aiQuotaProvider.overrideWith(
            (ref) =>
                const AiQuota(plan: 'free', used: 4, limit: 15, remaining: 11),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: BillingStatusCard())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gói hiện tại: Free'), findsOneWidget);
    expect(find.text('Đã dùng hôm nay: 4/15 lượt'), findsOneWidget);
    expect(find.textContaining('Đang chờ thanh toán'), findsOneWidget);
  });
}
