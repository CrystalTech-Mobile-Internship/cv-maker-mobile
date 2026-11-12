import 'package:cv_maker_mobile/features/auth/domain/models/auth_user.dart';
import 'package:cv_maker_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:cv_maker_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:cv_maker_mobile/features/auth/presentation/screens/account_screen.dart';
import 'package:cv_maker_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:cv_maker_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:cv_maker_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:cv_maker_mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('login exposes password recovery and accurately labels cloud', (
    tester,
  ) async {
    final repository = _ScreenAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.text('Máy chủ: Project kiểm thử'), findsOneWidget);
    expect(find.textContaining('Đã kết nối'), findsNothing);
  });

  testWidgets('forgot password validates before calling repository', (
    tester,
  ) async {
    final repository = _ScreenAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('reset-email')),
      'invalid',
    );
    await tester.tap(find.text('Gửi liên kết'));
    await tester.pump();

    expect(repository.passwordResetRequests, isEmpty);
    expect(find.text('Vui lòng nhập địa chỉ email hợp lệ.'), findsOneWidget);
  });

  testWidgets('Google button launches OAuth through the auth repository', (
    tester,
  ) async {
    final repository = _ScreenAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Tiếp tục với Google'));
    await tester.pump();

    expect(repository.googleSignInCalls, 1);
  });

  testWidgets('registration validates and forwards profile data', (
    tester,
  ) async {
    final repository = _ScreenAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));
    await tester.enterText(fields.at(0), 'Nguyễn Tuấn Anh');
    await tester.enterText(fields.at(1), 'owner@example.com');
    await tester.enterText(fields.at(2), 'Secret123');
    await tester.enterText(fields.at(3), 'Secret123');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng ký'));
    await tester.pump();

    expect(repository.lastDisplayName, 'Nguyễn Tuấn Anh');
    expect(repository.lastSignUpEmail, 'owner@example.com');
  });

  testWidgets('account shows authenticated identity and cloud metadata', (
    tester,
  ) async {
    const user = AuthUser(
      id: 'user-1',
      email: 'owner@example.com',
      displayName: 'Nguyễn Tuấn Anh',
      provider: 'email',
      isEmailConfirmed: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentAuthUserProvider.overrideWithValue(user)],
        child: const MaterialApp(home: AccountScreen()),
      ),
    );

    expect(find.text('owner@example.com'), findsOneWidget);
    expect(find.text('Đã xác nhận'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Chấm điểm CV'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Chấm điểm CV'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Nâng cấp Pro'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Nâng cấp Pro'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Lưu hồ sơ tài khoản'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Lưu hồ sơ tài khoản'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Đăng xuất'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Đăng xuất'), findsOneWidget);

    final logout = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Đăng xuất'),
    );
    expect(logout.style?.foregroundColor?.resolve({}), const Color(0xFFE11D48));
    expect(logout.style?.backgroundColor?.resolve({}), Colors.white);
  });

  testWidgets('auth screens fit a Samsung A11-sized logical viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _ScreenAuthRepository();
    for (final screen in <Widget>[
      const LoginScreen(),
      const RegisterScreen(),
      const ForgotPasswordScreen(),
      const ResetPasswordScreen(),
    ]) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(home: screen),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}

class _ScreenAuthRepository implements AuthRepository {
  final passwordResetRequests = <String>[];
  int googleSignInCalls = 0;
  String? lastDisplayName;
  String? lastSignUpEmail;

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
  Future<void> requestPasswordReset(String email) async {
    passwordResetRequests.add(email);
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<SignUpResult> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    lastDisplayName = displayName;
    lastSignUpEmail = email;
    throw const AuthFailure('Dừng sau khi xác nhận dữ liệu kiểm thử.');
  }

  @override
  Future<bool> signInWithGoogle() async {
    googleSignInCalls++;
    return true;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> updateDisplayName(String displayName) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> updatePassword(String password) =>
      throw UnimplementedError();

  @override
  Stream<AuthSessionChange> watchSession() => const Stream.empty();
}
