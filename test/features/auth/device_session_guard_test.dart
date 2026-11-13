import 'dart:async';
import 'dart:convert';

import 'package:cv_maker_mobile/features/auth/data/repositories/supabase_device_session_repository.dart';
import 'package:cv_maker_mobile/features/auth/domain/models/auth_user.dart';
import 'package:cv_maker_mobile/features/auth/domain/repositories/device_session_repository.dart';
import 'package:cv_maker_mobile/features/auth/presentation/controllers/device_session_guard.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = AuthUser(
  id: 'u1',
  email: 'me@example.com',
  displayName: 'Me',
  provider: 'email',
  isEmailConfirmed: true,
);

class _FakeRepository implements DeviceSessionRepository {
  DeviceSessionStatus status = DeviceSessionStatus.current;
  int claims = 0;
  bool failClaim = false;
  final replaced = StreamController<void>.broadcast();

  @override
  Future<void> claim() async {
    claims++;
    if (failClaim) throw Exception('offline');
  }

  @override
  Future<DeviceSessionStatus> check() async => status;

  @override
  Stream<void> watchReplaced(String userId) => replaced.stream;
}

void main() {
  late _FakeRepository repository;
  late int signOuts;
  late DeviceSessionGuard guard;

  setUp(() {
    repository = _FakeRepository();
    signOuts = 0;
    guard = DeviceSessionGuard(repository, onReplaced: () async => signOuts++);
  });

  tearDown(() => guard.stop());

  test('a fresh sign-in takes over the session for this device kind', () async {
    await guard.handle(
      const AuthSessionChange(event: AuthSessionEvent.signedIn, user: _user),
    );
    expect(repository.claims, 1);
    expect(signOuts, 0);
  });

  test('signs out when another device of the same kind signs in', () async {
    await guard.handle(
      const AuthSessionChange(event: AuthSessionEvent.signedIn, user: _user),
    );
    repository.replaced.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(signOuts, 1);
  });

  test('a restored session that was replaced signs out on start', () async {
    repository.status = DeviceSessionStatus.replaced;
    await guard.handle(
      const AuthSessionChange(event: AuthSessionEvent.initial, user: _user),
    );
    expect(signOuts, 1);
    expect(repository.claims, 0, reason: 'never takes the session back');
  });

  test('offline or server errors never sign the user out', () async {
    repository.status = DeviceSessionStatus.unknown;
    await guard.handle(
      const AuthSessionChange(event: AuthSessionEvent.initial, user: _user),
    );
    repository.failClaim = true;
    await guard.handle(
      const AuthSessionChange(event: AuthSessionEvent.signedIn, user: _user),
    );
    expect(signOuts, 0);
  });

  test('stops watching after sign-out', () async {
    await guard.handle(
      const AuthSessionChange(event: AuthSessionEvent.signedIn, user: _user),
    );
    await guard.handle(
      const AuthSessionChange(event: AuthSessionEvent.signedOut, user: null),
    );
    repository.replaced.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(signOuts, 0);
  });

  test('reads the session id from an access token', () {
    String encode(Map<String, Object> map) =>
        base64Url.encode(utf8.encode(jsonEncode(map))).replaceAll('=', '');
    final token =
        '${encode({'alg': 'HS256'})}.${encode({'session_id': 'abc-123'})}.sig';
    expect(sessionIdFromAccessToken(token), 'abc-123');
    expect(sessionIdFromAccessToken('not-a-token'), isNull);
    expect(sessionIdFromAccessToken(null), isNull);
  });
}
