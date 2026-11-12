import 'dart:async';

import 'package:cv_maker_mobile/app/app.dart';
import 'package:cv_maker_mobile/features/auth/domain/models/auth_user.dart';
import 'package:cv_maker_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:cv_maker_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('password recovery auth event opens reset password screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final events = StreamController<AuthSessionChange>();
    addTearDown(events.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_NavigationAuthRepository()),
          authSessionChangesProvider.overrideWith((ref) => events.stream),
        ],
        child: const CvMakerApp(startInGuestMode: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập tài khoản'), findsOneWidget);

    events.add(
      const AuthSessionChange(
        event: AuthSessionEvent.passwordRecovery,
        user: _NavigationAuthRepository.user,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đặt mật khẩu mới'), findsOneWidget);
    expect(find.text('Cập nhật mật khẩu'), findsOneWidget);
  });
}

class _NavigationAuthRepository implements AuthRepository {
  static const user = AuthUser(
    id: 'user-1',
    email: 'owner@example.com',
    displayName: 'Owner',
    provider: 'email',
    isEmailConfirmed: true,
  );

  @override
  String get backendLabel => 'Project kiểm thử';

  @override
  AuthUser? get currentUser => null;

  @override
  bool get isConfigured => true;

  @override
  Future<AuthUser> verifyRecoveryCode({
    required String email,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPasswordReset(String email) => throw UnimplementedError();

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<SignUpResult> signUp({
    required String displayName,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<bool> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> updateDisplayName(String displayName) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> updatePassword(String password) async => user;

  @override
  Stream<AuthSessionChange> watchSession() => const Stream.empty();
}
