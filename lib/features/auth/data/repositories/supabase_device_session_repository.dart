import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../domain/repositories/device_session_repository.dart';

/// Device kind used for the "one browser + one phone" rule.
String get currentDevicePlatform => kIsWeb ? 'web' : 'mobile';

/// Reads the `session_id` claim of a Supabase access token.
String? sessionIdFromAccessToken(String? token) {
  if (token == null) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    final id = payload is Map ? payload['session_id'] : null;
    return id is String && id.isNotEmpty ? id : null;
  } catch (_) {
    return null;
  }
}

class SupabaseDeviceSessionRepository implements DeviceSessionRepository {
  SupabaseDeviceSessionRepository({SupabaseClient? client})
    : _provided = client;

  final SupabaseClient? _provided;

  SupabaseClient? get _client => _provided ?? SupabaseService.client;

  String? get _sessionId =>
      sessionIdFromAccessToken(_client?.auth.currentSession?.accessToken);

  @override
  Future<void> claim() async {
    final client = _client;
    if (client == null || client.auth.currentSession == null) return;
    await client.rpc(
      'claim_device_session',
      params: {
        'p_platform': currentDevicePlatform,
        'p_device_label': kIsWeb ? 'web' : defaultTargetPlatform.name,
      },
    );
  }

  @override
  Future<DeviceSessionStatus> check() async {
    final client = _client;
    final mine = _sessionId;
    if (client == null || mine == null) return DeviceSessionStatus.unknown;
    try {
      final rows = await client
          .from('user_device_sessions')
          .select('session_id')
          .eq('platform', currentDevicePlatform)
          .limit(1);
      final list = rows as List;
      if (list.isEmpty) {
        await claim();
        return DeviceSessionStatus.current;
      }
      final active = '${(list.first as Map)['session_id']}';
      return active == mine
          ? DeviceSessionStatus.current
          : DeviceSessionStatus.replaced;
    } catch (_) {
      return DeviceSessionStatus.unknown;
    }
  }

  @override
  Stream<void> watchReplaced(String userId) {
    final client = _client;
    if (client == null) return const Stream.empty();

    late final StreamController<void> controller;
    RealtimeChannel? channel;
    controller = StreamController<void>(
      onListen: () {
        channel = client
            .channel('device-session-$userId-$currentDevicePlatform')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'user_device_sessions',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (payload) {
                final row = payload.newRecord;
                if (row['platform'] != currentDevicePlatform) return;
                final active = row['session_id'];
                final mine = _sessionId;
                if (active is String && mine != null && active != mine) {
                  if (!controller.isClosed) controller.add(null);
                }
              },
            )
            .subscribe();
      },
      onCancel: () async {
        final active = channel;
        channel = null;
        if (active != null) await client.removeChannel(active);
      },
    );
    return controller.stream;
  }
}

final deviceSessionRepositoryProvider = Provider<DeviceSessionRepository>(
  (ref) => SupabaseDeviceSessionRepository(),
);
