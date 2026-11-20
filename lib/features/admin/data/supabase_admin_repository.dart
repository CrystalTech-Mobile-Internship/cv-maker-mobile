import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/network/supabase_client.dart';
import '../../support/domain/support_models.dart';
import '../domain/admin_models.dart';

/// Admin calls go through server functions that check `is_admin()` first.
class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository({SupabaseClient? client}) : _provided = client;

  final SupabaseClient? _provided;

  SupabaseClient? get _maybeClient => _provided ?? SupabaseService.client;

  SupabaseClient get _client {
    final client = _maybeClient;
    if (client == null || client.auth.currentUser == null) {
      throw AdminFailure(tr('Hãy đăng nhập lại.', 'Please sign in again.'));
    }
    return client;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AdminFailure {
      rethrow;
    } on PostgrestException catch (error) {
      debugPrint('admin call failed: ${error.code} ${error.message}');
      throw AdminFailure(
        error.code == '42501'
            ? tr(
                'Tài khoản này không có quyền quản trị.',
                'This account is not an admin.',
              )
            : tr(
                'Máy chủ chưa xử lý được. Hãy thử lại.',
                'The server could not do that. Please try again.',
              ),
      );
    } catch (error) {
      debugPrint('admin call failed: $error');
      throw AdminFailure(
        tr('Không kết nối được máy chủ.', 'Could not reach the server.'),
      );
    }
  }

  List<Map<String, dynamic>> _rows(Object? data) => [
    if (data is List)
      for (final row in data)
        if (row is Map) Map<String, dynamic>.from(row),
  ];

  @override
  Future<bool> isAdmin() async {
    final client = _maybeClient;
    if (client == null || client.auth.currentUser == null) return false;
    try {
      return await client.rpc('is_admin') == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AdminStats> stats() => _guard(() async {
    final rows = _rows(await _client.rpc('admin_stats'));
    return AdminStats.fromRow(rows.isEmpty ? const {} : rows.first);
  });

  @override
  Future<List<SupportThread>> threads() => _guard(() async {
    final rows = _rows(await _client.rpc('admin_support_threads'));
    return rows.map(SupportThread.fromRow).toList(growable: false);
  });

  @override
  Stream<void> supportChanges() => _client
      .from('support_messages')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(1)
      .map((_) {});

  @override
  Stream<List<SupportMessage>> conversation(String userId) => _client
      .from('support_messages')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: true)
      .map(
        (rows) => rows
            .map((row) => SupportMessage.fromRow(Map.of(row)))
            .toList(growable: false),
      );

  @override
  Future<void> reply(String userId, String body) => _guard(() async {
    final text = body.trim();
    if (text.isEmpty) return;
    await _client.rpc(
      'admin_reply_support',
      params: {'p_user_id': userId, 'p_body': text},
    );
  });

  @override
  Future<void> markRead(String userId) => _guard(() async {
    await _client.rpc('admin_mark_support_read', params: {'p_user_id': userId});
  });

  @override
  Future<List<AdminProRequest>> proRequests() => _guard(() async {
    final rows = _rows(await _client.rpc('admin_pro_requests'));
    return rows.map(AdminProRequest.fromRow).toList(growable: false);
  });

  @override
  Future<List<AdminPaymentEvent>> paymentEvents() => _guard(() async {
    final rows = _rows(await _client.rpc('admin_payment_events'));
    return rows.map(AdminPaymentEvent.fromRow).toList(growable: false);
  });

  @override
  Future<void> reviewProRequest(String requestId, {required bool approve}) =>
      _guard(() async {
        await _client.rpc(
          'admin_review_pro_request',
          params: {'p_request_id': requestId, 'p_approve': approve},
        );
      });
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => SupabaseAdminRepository(),
);
