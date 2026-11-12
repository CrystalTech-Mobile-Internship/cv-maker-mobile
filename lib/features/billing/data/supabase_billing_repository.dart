import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/billing_models.dart';

class SupabaseBillingRepository implements BillingRepository {
  SupabaseBillingRepository({SupabaseClient? client}) : _provided = client;

  final SupabaseClient? _provided;

  SupabaseClient get _client {
    final client = _provided ?? SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      throw const BillingFailure('Hãy đăng nhập để nâng cấp tài khoản.');
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
          .select('id, plan, transfer_code, status, created_at, admin_note')
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
      throw const BillingFailure(
        'Máy chủ chưa hỗ trợ nâng cấp. Hãy thử lại sau.',
      );
    } catch (_) {
      throw const BillingFailure('Không kết nối được máy chủ.');
    }
  }

  @override
  Future<ProUpgradeRequest> submitRequest(ProPlan plan) async {
    try {
      final client = _client;
      final row = await client
          .from('pro_upgrade_requests')
          .insert({
            'plan': plan.value,
            'transfer_code': proTransferCode(client.auth.currentUser!.id, plan),
          })
          .select('id, plan, transfer_code, status, created_at, admin_note')
          .single();
      return mapRequest(row);
    } on BillingFailure {
      rethrow;
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const BillingFailure('Bạn đã có một yêu cầu đang chờ xác nhận.');
      }
      throw const BillingFailure('Không gửi được yêu cầu. Hãy thử lại sau.');
    } catch (_) {
      throw const BillingFailure('Không kết nối được máy chủ.');
    }
  }

  static ProUpgradeRequest mapRequest(Map<String, dynamic> row) {
    final status = switch (row['status']) {
      'approved' => ProRequestStatus.approved,
      'rejected' => ProRequestStatus.rejected,
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
      adminNote: row['admin_note'] as String?,
    );
  }
}

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => SupabaseBillingRepository(),
);

/// Billing status of the signed-in user; refresh with `ref.invalidate`.
final billingStatusProvider = FutureProvider.autoDispose<BillingStatus>(
  (ref) => ref.watch(billingRepositoryProvider).fetchStatus(),
);
