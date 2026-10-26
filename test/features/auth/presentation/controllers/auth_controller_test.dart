import 'package:cv_maker_mobile/features/auth/data/guest_session_service.dart';
import 'package:cv_maker_mobile/features/auth/domain/models/auth_user.dart';
import 'package:cv_maker_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:cv_maker_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthRepository repository;
  late AuthController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = _FakeAuthRepository();
    controller = AuthController(
      repository: repository,
      guestSessionService: const GuestSessionService(),
    );
  });

  test(
    'successful sign in leaves guest mode and returns the account',
    () async {
      await const GuestSessionService().setGuestMode(true);

      final result = await controller.signIn(
        email: 'owner@example.com',
        password: 'secret123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.user?.id, 'user-1');
      expect(repository.lastEmail, 'owner@example.com');
      expect(await const GuestSessionService().isGuestMode(), isFalse);
    },
  );

  test('password reset rejects invalid email without a cloud call', () async {
    final result = await controller.requestPasswordReset('not-an-email');

    expect(result.isSuccess, isFalse);
    expect(repository.passwordResetRequests, isEmpty);
  });

  test('registration sends the normalized display name', () async {
    final result = await controller.signUp(
      displayName: '  Nguyễn Tuấn Anh  ',
      email: 'owner@example.com',
      password: 'Secret123',
      confirmation: 'Secret123',
    );

    expect(result.isSuccess, isTrue);
    expect(repository.lastDisplayName, 'Nguyễn Tuấn Anh');
  });

  test('password update requires matching passwords', () async {
    final result = await controller.updatePassword(
      password: 'new-secret',
      confirmation: 'different',
    );

    expect(result.isSuccess, isFalse);
    expect(repository.updatedPasswords, isEmpty);
  });

  test('guest choice persists without calling Supabase', () async {
    final result = await controller.continueAsGuest();

    expect(result.isSuccess, isTrue);
    expect(await const GuestSessionService().isGuestMode(), isTrue);
    expect(repository.signInCalls, 0);
  });

  test(
    'Google OAuth reports success after the browser flow launches',
    () async {
      final result = await controller.signInWithGoogle();

      expect(result.isSuccess, isTrue);
      expect(result.message, 'Đã mở trang đăng nhập Google.');
      expect(repository.googleSignInCalls, 1);
    },
  );

  test('Google OAuth reports failure when the browser cannot launch', () async {
    repository.googleLaunchResult = false;

    final result = await controller.signInWithGoogle();

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Không thể mở trang đăng nhập Google.');
    expect(repository.googleSignInCalls, 1);
  });
}

class _FakeAuthRepository implements AuthRepository {
  static const user = AuthUser(
    id: 'user-1',
    email: 'owner@example.com',
    displayName: 'Owner',
    provider: 'email',
    isEmailConfirmed: true,
  );

  String? lastEmail;
  String? lastDisplayName;
  int signInCalls = 0;
  int googleSignInCalls = 0;
  bool googleLaunchResult = true;
  final passwordResetRequests = <String>[];
  final updatedPasswords = <String>[];

  @override
  String get backendLabel => 'Project kiểm thử';

  @override
  AuthUser? get currentUser => user;

  @override
  bool get isConfigured => true;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastEmail = email;
    return user;
  }

  @override
  Future<SignUpResult> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    lastDisplayName = displayName;
    return const SignUpResult(user: user, requiresEmailConfirmation: false);
  }

  @override
  Future<bool> signInWithGoogle() async {
    googleSignInCalls++;
    return googleLaunchResult;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    passwordResetRequests.add(email);
  }

  @override
  Future<AuthUser> updatePassword(String password) async {
    updatedPasswords.add(password);
    return user;
  }

  @override
  Future<AuthUser> updateDisplayName(String displayName) async => user;

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthSessionChange> watchSession() => const Stream.empty();
}
