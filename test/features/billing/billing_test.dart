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
  Future<ProUpgradeRequest> submitRequest(ProPlan plan) =>
      throw UnimplementedError();
}

void main() {
  test('builds a per-account transfer code accepted by the database', () {
    final code = proTransferCode(
      '1a2b3c4d-0000-4000-8000-000000000000',
      ProPlan.lifetime,
    );
    expect(code, 'CVPRO-LIFETIME-1A2B3C4D');
    expect(RegExp(r'^CVPRO-[A-Z0-9-]{4,40}$').hasMatch(code), isTrue);
  });

  test('maps request rows', () {
    final request = SupabaseBillingRepository.mapRequest({
      'id': 'r1',
      'plan': 'monthly',
      'transfer_code': 'CVPRO-MONTHLY-ABCD1234',
      'status': 'pending',
      'created_at': '2026-11-12T00:00:00Z',
    });
    expect(request.plan, ProPlan.monthly);
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
                  plan: ProPlan.lifetime,
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
    expect(find.text('Lượt AI hôm nay: 4/15'), findsOneWidget);
    expect(find.textContaining('đang chờ xác nhận'), findsOneWidget);
  });
}
