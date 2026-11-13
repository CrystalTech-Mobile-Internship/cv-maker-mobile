import 'dart:async';

import '../../domain/models/auth_user.dart';
import '../../domain/repositories/device_session_repository.dart';

/// Keeps an account signed in on at most one browser and one phone.
///
/// A fresh sign-in takes over the session for this kind of device. A device
/// that was taken over (seen live, or when the app starts) calls
/// [onReplaced], which signs it out. Errors never sign anyone out.
class DeviceSessionGuard {
  DeviceSessionGuard(this._repository, {required this.onReplaced});

  final DeviceSessionRepository _repository;
  final Future<void> Function() onReplaced;

  StreamSubscription<void>? _watch;
  String? _watchedUser;
  bool _signingOut = false;

  Future<void> handle(AuthSessionChange change) async {
    final user = change.user;
    switch (change.event) {
      case AuthSessionEvent.signedOut:
        await stop();
      case AuthSessionEvent.signedIn:
        if (user == null) return;
        try {
          await _repository.claim();
        } catch (_) {
          // Offline: the next start re-checks the session.
        }
        _start(user.id);
      case AuthSessionEvent.initial:
        if (user == null) {
          await stop();
          return;
        }
        final status = await _repository.check();
        if (status == DeviceSessionStatus.replaced) {
          await _replaced();
          return;
        }
        _start(user.id);
      default:
        if (user != null) _start(user.id);
    }
  }

  void _start(String userId) {
    if (_watch != null && _watchedUser == userId) return;
    _watch?.cancel();
    _watchedUser = userId;
    _watch = _repository
        .watchReplaced(userId)
        .listen((_) => _replaced(), onError: (_) {});
  }

  Future<void> _replaced() async {
    if (_signingOut) return;
    _signingOut = true;
    try {
      await stop();
      await onReplaced();
    } finally {
      _signingOut = false;
    }
  }

  Future<void> stop() async {
    await _watch?.cancel();
    _watch = null;
    _watchedUser = null;
  }
}
