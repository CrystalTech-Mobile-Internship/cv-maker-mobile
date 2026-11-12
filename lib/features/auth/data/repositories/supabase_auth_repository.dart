import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_auth_data_source.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._dataSource);

  final SupabaseAuthDataSource _dataSource;

  @override
  bool get isConfigured => _dataSource.optionalClient != null;

  @override
  String get backendLabel => _dataSource.backendLabel;

  @override
  AuthUser? get currentUser => _mapUser(_dataSource.currentUser);

  @override
  Stream<AuthSessionChange> watchSession() async* {
    yield AuthSessionChange(event: AuthSessionEvent.initial, user: currentUser);
    await for (final state in _dataSource.watchAuthState()) {
      yield AuthSessionChange(
        event: _mapEvent(state.event),
        user: _mapUser(state.session?.user ?? _dataSource.currentUser),
      );
    }
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dataSource.signIn(
        email: email,
        password: password,
      );
      final user = _mapUser(response.user);
      if (user == null || response.session == null) {
        throw const AuthFailure(
          'Không tạo được phiên đăng nhập. Hãy kiểm tra email xác nhận.',
        );
      }
      return user;
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<SignUpResult> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dataSource.signUp(
        displayName: displayName,
        email: email,
        password: password,
      );
      return SignUpResult(
        user: _mapUser(response.user),
        requiresEmailConfirmation: response.session == null,
      );
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      return await _dataSource.signInWithGoogle();
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _dataSource.requestPasswordReset(email);
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<AuthUser> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dataSource.verifyRecoveryCode(
        email: email,
        code: code,
      );
      final user = _mapUser(response.user);
      if (user == null) {
        throw const AuthFailure('Mã khôi phục không đúng hoặc đã hết hạn.');
      }
      return user;
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('expired') ||
          message.contains('invalid') ||
          message.contains('token')) {
        throw AuthFailure(
          'Mã khôi phục không đúng hoặc đã hết hạn.',
          cause: error,
        );
      }
      throw _mapFailure(error);
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<AuthUser> updatePassword(String password) async {
    try {
      final response = await _dataSource.updatePassword(password);
      final user = _mapUser(response.user);
      if (user == null) {
        throw const AuthFailure('Không thể cập nhật mật khẩu.');
      }
      return user;
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<AuthUser> updateDisplayName(String displayName) async {
    try {
      final response = await _dataSource.updateDisplayName(displayName);
      final user = _mapUser(response.user);
      if (user == null) {
        throw const AuthFailure('Không thể cập nhật hồ sơ tài khoản.');
      }
      return user;
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final preferredName = metadata['display_name']?.toString().trim() ?? '';
    final fallbackName = metadata['full_name']?.toString().trim() ?? '';
    final displayName = preferredName.isNotEmpty ? preferredName : fallbackName;
    final provider =
        user.appMetadata['provider']?.toString() ??
        (user.identities?.isNotEmpty == true
            ? user.identities!.first.provider
            : 'email');
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      displayName: displayName,
      provider: provider,
      isEmailConfirmed: user.emailConfirmedAt != null,
    );
  }

  AuthSessionEvent _mapEvent(AuthChangeEvent event) {
    if (event == AuthChangeEvent.signedIn) return AuthSessionEvent.signedIn;
    if (event == AuthChangeEvent.signedOut) return AuthSessionEvent.signedOut;
    if (event == AuthChangeEvent.passwordRecovery) {
      return AuthSessionEvent.passwordRecovery;
    }
    if (event == AuthChangeEvent.tokenRefreshed) {
      return AuthSessionEvent.tokenRefreshed;
    }
    if (event == AuthChangeEvent.userUpdated) {
      return AuthSessionEvent.userUpdated;
    }
    if (event == AuthChangeEvent.initialSession) {
      return AuthSessionEvent.initial;
    }
    return AuthSessionEvent.other;
  }

  AuthFailure _mapFailure(Object error) {
    if (error is AuthFailure) return error;
    if (error is StateError) return AuthFailure(error.message, cause: error);
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        return AuthFailure('Email hoặc mật khẩu không đúng.', cause: error);
      }
      if (message.contains('email not confirmed')) {
        return AuthFailure(
          'Email chưa được xác nhận. Hãy kiểm tra hộp thư.',
          cause: error,
        );
      }
      if (message.contains('user already registered')) {
        return AuthFailure(
          'Email này đã được đăng ký. Hãy chuyển sang đăng nhập.',
          cause: error,
        );
      }
      if (message.contains('password')) {
        return AuthFailure(
          'Mật khẩu chưa đáp ứng yêu cầu bảo mật.',
          cause: error,
        );
      }
      return AuthFailure(error.message, cause: error);
    }
    return AuthFailure(
      'Không thể kết nối dịch vụ tài khoản. Hãy kiểm tra mạng và thử lại.',
      cause: error,
    );
  }
}
