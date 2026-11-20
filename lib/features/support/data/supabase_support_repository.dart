import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/network/supabase_client.dart';
import '../domain/support_models.dart';

class SupabaseSupportRepository implements SupportRepository {
  SupabaseSupportRepository({SupabaseClient? client}) : _provided = client;

  final SupabaseClient? _provided;

  SupabaseClient get _client {
    final client = _provided ?? SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      throw SupportFailure(
        tr('Hãy đăng nhập để nhắn hỗ trợ.', 'Sign in to message support.'),
      );
    }
    return client;
  }

  @override
  Stream<List<SupportMessage>> watch() {
    final client = _client;
    return client
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', client.auth.currentUser!.id)
        .order('created_at')
        .map(
          (rows) => rows
              .map((row) => SupportMessage.fromRow(Map.of(row)))
              .toList(growable: false),
        );
  }

  @override
  Future<void> send(String body) async {
    final text = body.trim();
    if (text.isEmpty) return;
    final client = _client;
    final String id;
    try {
      final row = await client
          .from('support_messages')
          .insert({'body': text.length > 2000 ? text.substring(0, 2000) : text})
          .select('id')
          .single();
      id = '${row['id']}';
    } on PostgrestException catch (error) {
      throw SupportFailure(
        error.message.contains('too many')
            ? tr(
                'Bạn gửi hơi nhanh. Hãy đợi vài phút rồi gửi tiếp.',
                'You are sending too fast. Please wait a few minutes.',
              )
            : tr(
                'Chưa gửi được tin nhắn. Hãy thử lại.',
                'Could not send the message. Please try again.',
              ),
      );
    } catch (_) {
      throw SupportFailure(
        tr('Không kết nối được máy chủ.', 'Could not reach the server.'),
      );
    }

    // The message is already saved; email delivery is best effort.
    try {
      await client.functions.invoke('support-notify', body: {'messageId': id});
    } catch (error) {
      debugPrint('support-notify failed: $error');
    }
  }
}

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupabaseSupportRepository(),
);

final supportMessagesProvider =
    StreamProvider.autoDispose<List<SupportMessage>>(
      (ref) => ref.watch(supportRepositoryProvider).watch(),
    );
