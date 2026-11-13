import '../models/auth_user.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class SignUpResult {
  const SignUpResult({
    required this.user,
    required this.requiresEmailConfirmation,
  });

  final AuthUser? user;
  final bool requiresEmailConfirmation;
}

abstract interface class AuthRepository {
  bool get isConfigured;

  String get backendLabel;

  AuthUser? get currentUser;

  Stream<AuthSessionChange> watchSession();

  Future<AuthUser> signIn({required String email, required String password});

  Future<SignUpResult> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  Future<bool> signInWithGoogle();

  Future<void> requestPasswordReset(String email);

  /// Starts a recovery session from the code in the reset email.
  Future<AuthUser> verifyRecoveryCode({
    required String email,
    required String code,
  });

  Future<AuthUser> updatePassword(String password);

  Future<AuthUser> updateDisplayName(String displayName);

  Future<void> signOut();
}
