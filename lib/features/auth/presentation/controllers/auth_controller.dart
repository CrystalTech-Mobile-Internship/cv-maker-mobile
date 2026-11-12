import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/guest_session_service.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthActionState {
  const AuthActionState({this.isLoading = false});

  final bool isLoading;

  AuthActionState copyWith({bool? isLoading}) =>
      AuthActionState(isLoading: isLoading ?? this.isLoading);
}

class AuthActionResult {
  const AuthActionResult._({
    required this.isSuccess,
    required this.message,
    this.user,
    this.requiresEmailConfirmation = false,
  });

  factory AuthActionResult.success({
    required String message,
    AuthUser? user,
    bool requiresEmailConfirmation = false,
  }) => AuthActionResult._(
    isSuccess: true,
    message: message,
    user: user,
    requiresEmailConfirmation: requiresEmailConfirmation,
  );

  factory AuthActionResult.failure(String message) =>
      AuthActionResult._(isSuccess: false, message: message);

  final bool isSuccess;
  final String message;
  final AuthUser? user;
  final bool requiresEmailConfirmation;
}

class AuthController extends StateNotifier<AuthActionState> {
  AuthController({
    required AuthRepository repository,
    required GuestSessionService guestSessionService,
  }) : _repository = repository,
       _guestSessionService = guestSessionService,
       super(const AuthActionState());

  final AuthRepository _repository;
  final GuestSessionService _guestSessionService;

  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) {
    return _run(() async {
      final validation = _validateCredentials(email, password);
      if (validation != null) throw AuthFailure(validation);
      final user = await _repository.signIn(
        email: email.trim(),
        password: password,
      );
      await _guestSessionService.setGuestMode(false);
      return AuthActionResult.success(
        message: 'Đăng nhập thành công.',
        user: user,
      );
    });
  }

  Future<AuthActionResult> signUp({
    required String displayName,
    required String email,
    required String password,
    required String confirmation,
  }) {
    return _run(() async {
      final normalizedName = displayName.trim();
      if (normalizedName.length < 2 || normalizedName.length > 100) {
        throw const AuthFailure('Họ và tên phải có từ 2 đến 100 ký tự.');
      }
      final validation = _validateCredentials(email, password);
      if (validation != null) throw AuthFailure(validation);
      if (password.length < 8) {
        throw const AuthFailure('Mật khẩu phải có ít nhất 8 ký tự.');
      }
      if (password != confirmation) {
        throw const AuthFailure('Mật khẩu xác nhận không khớp.');
      }
      final result = await _repository.signUp(
        displayName: normalizedName,
        email: email.trim(),
        password: password,
      );
      if (!result.requiresEmailConfirmation) {
        await _guestSessionService.setGuestMode(false);
      }
      return AuthActionResult.success(
        message: result.requiresEmailConfirmation
            ? 'Đăng ký thành công. Hãy mở email để xác nhận tài khoản.'
            : 'Tạo tài khoản và đăng nhập thành công.',
        user: result.user,
        requiresEmailConfirmation: result.requiresEmailConfirmation,
      );
    });
  }

  Future<AuthActionResult> signInWithGoogle() {
    return _run(() async {
      final launched = await _repository.signInWithGoogle();
      if (!launched) {
        throw const AuthFailure('Không thể mở trang đăng nhập Google.');
      }
      return AuthActionResult.success(message: 'Đã mở trang đăng nhập Google.');
    });
  }

  /// OAuth only opens an external browser. Guest mode must be cleared after
  /// Supabase confirms a real session, not when the browser merely launches.
  Future<void> handleSessionChange(AuthSessionChange change) async {
    final isAuthenticated =
        change.user != null &&
        (change.event == AuthSessionEvent.signedIn ||
            change.event == AuthSessionEvent.initial ||
            change.event == AuthSessionEvent.tokenRefreshed);
    if (isAuthenticated) {
      await _guestSessionService.setGuestMode(false);
    }
  }

  Future<AuthActionResult> continueAsGuest() {
    return _run(() async {
      await _guestSessionService.setGuestMode(true);
      return AuthActionResult.success(
        message:
            'Bạn đang dùng ứng dụng không cần tài khoản; dữ liệu lưu trên máy.',
      );
    });
  }

  Future<AuthActionResult> requestPasswordReset(String email) {
    return _run(() async {
      final normalizedEmail = email.trim();
      if (!_isValidEmail(normalizedEmail)) {
        throw const AuthFailure('Vui lòng nhập địa chỉ email hợp lệ.');
      }
      await _repository.requestPasswordReset(normalizedEmail);
      return AuthActionResult.success(
        message: 'Đã gửi liên kết đặt lại mật khẩu. Hãy kiểm tra email.',
      );
    });
  }

  Future<AuthActionResult> verifyRecoveryCode({
    required String email,
    required String code,
  }) {
    return _run(() async {
      final normalizedEmail = email.trim();
      final normalizedCode = code.replaceAll(RegExp(r'\s'), '');
      if (!_isValidEmail(normalizedEmail)) {
        throw const AuthFailure('Vui lòng nhập địa chỉ email hợp lệ.');
      }
      if (!RegExp(r'^\d{6,10}$').hasMatch(normalizedCode)) {
        throw const AuthFailure('Mã khôi phục gồm 6–10 chữ số trong email.');
      }
      final user = await _repository.verifyRecoveryCode(
        email: normalizedEmail,
        code: normalizedCode,
      );
      return AuthActionResult.success(
        message: 'Mã hợp lệ. Hãy đặt mật khẩu mới.',
        user: user,
      );
    });
  }

  Future<AuthActionResult> updatePassword({
    required String password,
    required String confirmation,
  }) {
    return _run(() async {
      if (password.length < 8) {
        throw const AuthFailure('Mật khẩu mới phải có ít nhất 8 ký tự.');
      }
      if (password != confirmation) {
        throw const AuthFailure('Mật khẩu xác nhận không khớp.');
      }
      final user = await _repository.updatePassword(password);
      return AuthActionResult.success(
        message: 'Đã cập nhật mật khẩu thành công.',
        user: user,
      );
    });
  }

  Future<AuthActionResult> updateDisplayName(String displayName) {
    return _run(() async {
      final normalizedName = displayName.trim();
      if (normalizedName.length < 2 || normalizedName.length > 100) {
        throw const AuthFailure('Tên hiển thị phải có từ 2 đến 100 ký tự.');
      }
      final user = await _repository.updateDisplayName(normalizedName);
      return AuthActionResult.success(
        message: 'Đã cập nhật hồ sơ tài khoản.',
        user: user,
      );
    });
  }

  Future<AuthActionResult> signOut() {
    return _run(() async {
      await _repository.signOut();
      await _guestSessionService.setGuestMode(false);
      return AuthActionResult.success(message: 'Đã đăng xuất.');
    });
  }

  Future<AuthActionResult> _run(
    Future<AuthActionResult> Function() action,
  ) async {
    if (state.isLoading) {
      return AuthActionResult.failure(
        'Một thao tác tài khoản đang được xử lý.',
      );
    }
    state = state.copyWith(isLoading: true);
    try {
      return await action();
    } on AuthFailure catch (error) {
      return AuthActionResult.failure(error.message);
    } catch (_) {
      return AuthActionResult.failure(
        'Đã xảy ra lỗi không mong muốn. Hãy thử lại.',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  String? _validateCredentials(String email, String password) {
    if (!_isValidEmail(email.trim())) return 'Email không hợp lệ.';
    if (password.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.';
    return null;
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
}
