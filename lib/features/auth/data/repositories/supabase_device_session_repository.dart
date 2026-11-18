import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/auth_callback_parser.dart';
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
  String? _lastClaimedSessionId;

  SupabaseClient? get _client => _provided ?? SupabaseService.client;

  String? get _sessionId =>
      sessionIdFromAccessToken(_client?.auth.currentSession?.accessToken);

  @override
  Future<void> claim() async {
    final client = _client;
    final session = client?.auth.currentSession;
    if (client == null || session == null) return;
    _lastClaimedSessionId = sessionIdFromAccessToken(session.accessToken);
    await client.rpc(
      'claim_device_session',
      params: {
        'p_platform': currentDevicePlatform,
        'p_device_label': kIsWeb ? 'web' : defaultTargetPlatform.name,
      },
    );
    markInitialOAuthCallbackHandled();
  }

  @override
  Future<void> release() async {
    final client = _client;
    final mine = _sessionId ?? _lastClaimedSessionId;
    _lastClaimedSessionId = null;
    if (client == null) return;
    try {
      final params = <String, dynamic>{'p_platform': currentDevicePlatform};
      if (mine != null) params['p_session_id'] = mine;
      await client.rpc('release_device_session', params: params);
    } catch (_) {
      try {
        var query = client
            .from('user_device_sessions')
            .delete()
            .eq('platform', currentDevicePlatform);
        if (mine != null) {
          query = query.eq('session_id', mine);
        }
        await query;
      } catch (_) {}
    }
  }

  @override
  Future<DeviceSessionStatus> check() async {
    final client = _client;
    final mine = _sessionId;
    if (client == null || mine == null) return DeviceSessionStatus.unknown;
    if (isInitialOAuthCallback || isOAuthCallbackUri(Uri.base)) {
      await claim();
      return DeviceSessionStatus.current;
    }
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
      if (active == mine || active == _lastClaimedSessionId) {
        return DeviceSessionStatus.current;
      }
      return DeviceSessionStatus.replaced;
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
                final mine = _sessionId ?? _lastClaimedSessionId;
                if (active is String &&
                    active != _lastClaimedSessionId &&
                    mine != null &&
                    active != mine) {
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
