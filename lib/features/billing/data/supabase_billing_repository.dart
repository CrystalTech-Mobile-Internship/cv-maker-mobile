import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../domain/billing_models.dart';

class SupabaseBillingRepository implements BillingRepository {
  SupabaseBillingRepository({SupabaseClient? client}) : _provided = client;

  final SupabaseClient? _provided;

  SupabaseClient get _client {
    final client = _provided ?? SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      throw BillingFailure(
        tr(
          'Hãy đăng nhập để nâng cấp tài khoản.',
          'Sign in to upgrade your account.',
        ),
      );
    }
    return client;
  }

  @override
  Future<BillingStatus> fetchStatus() async {
    try {
      final client = _client;
      final userId = client.auth.currentUser!.id;
      final entitlement = await client
          .from('user_entitlements')
          .select('plan, pro_until')
          .eq('user_id', userId)
          .maybeSingle();
      final requests = await client
          .from('pro_upgrade_requests')
          .select(
            'id, plan, transfer_code, status, created_at, admin_note, amount',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);
      final proUntil = DateTime.tryParse(
        '${entitlement?['pro_until'] ?? ''}',
      )?.toUtc();
      final isPro =
          entitlement?['plan'] == 'pro' &&
          (proUntil == null || proUntil.isAfter(DateTime.now().toUtc()));
      final rows = (requests as List).whereType<Map>().toList();
      return BillingStatus(
        isPro: isPro,
        proUntil: isPro ? proUntil : null,
        latestRequest: rows.isEmpty
            ? null
            : mapRequest(Map<String, dynamic>.from(rows.first)),
      );
    } on BillingFailure {
      rethrow;
    } on PostgrestException {
      throw BillingFailure(
        tr(
          'Chưa tải được gói của bạn. Hãy thử lại sau.',
          'Could not load your plan. Please try again later.',
        ),
      );
    } catch (_) {
      throw BillingFailure(
        tr('Không kết nối được máy chủ.', 'Could not reach the server.'),
      );
    }
  }

  @override
  Future<ProUpgradeRequest> startCheckout(ProPlan plan) async {
    try {
      final client = _client;
      final row = await client.rpc(
        'start_pro_checkout',
        params: {'p_plan': plan.value},
      );
      return mapRequest(Map<String, dynamic>.from(row as Map));
    } on BillingFailure {
      rethrow;
    } on PostgrestException {
      throw BillingFailure(
        tr(
          'Chưa tạo được mã thanh toán. Hãy thử lại sau.',
          'Could not start the payment. Please try again later.',
        ),
      );
    } catch (_) {
      throw BillingFailure(
        tr('Không kết nối được máy chủ.', 'Could not reach the server.'),
      );
    }
  }

  static ProUpgradeRequest mapRequest(Map<String, dynamic> row) {
    final status = switch (row['status']) {
      'approved' => ProRequestStatus.approved,
      'rejected' => ProRequestStatus.rejected,
      'expired' => ProRequestStatus.expired,
      _ => ProRequestStatus.pending,
    };
    return ProUpgradeRequest(
      id: '${row['id']}',
      plan: ProPlan.fromValue(row['plan'] as String?),
      transferCode: '${row['transfer_code'] ?? ''}',
      status: status,
      createdAt:
          DateTime.tryParse('${row['created_at']}')?.toUtc() ??
          DateTime.now().toUtc(),
      amount: (row['amount'] as num?)?.toInt(),
      adminNote: row['admin_note'] as String?,
    );
  }
}

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => SupabaseBillingRepository(),
);

/// Whether the signed-in account currently has Pro.
final isProProvider = Provider<bool>((ref) {
  if (ref.watch(currentAuthUserProvider) == null) return false;
  return ref.watch(billingStatusProvider).valueOrNull?.isPro ?? false;
});

/// Billing status of the signed-in user; refresh with `ref.invalidate`.
final billingStatusProvider = FutureProvider.autoDispose<BillingStatus>(
  (ref) => ref.watch(billingRepositoryProvider).fetchStatus(),
);
