import 'package:cv_maker_mobile/features/auth/domain/models/auth_user.dart';
import 'package:cv_maker_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:cv_maker_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:cv_maker_mobile/features/billing/data/supabase_billing_repository.dart';
import 'package:cv_maker_mobile/features/billing/domain/billing_models.dart';
import 'package:cv_maker_mobile/features/billing/presentation/screens/pro_upgrade_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guest can compare plans but must sign in before payment', (
    tester,
  ) async {
    await tester.pumpWidget(_appWithUser(null));

    expect(find.text('Nâng cấp Pro'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Đăng nhập để nâng cấp'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Đăng nhập để nâng cấp'), findsOneWidget);
    expect(find.text('Quét VietQR để nâng cấp'), findsNothing);
    expect(find.text('Tôi đã chuyển khoản'), findsNothing);
  });

  testWidgets('authenticated user sees plans and transfer details', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWithUser(
        const AuthUser(
          id: 'user-1',
          email: 'owner@example.com',
          displayName: 'Owner',
          provider: 'email',
          isEmailConfirmed: true,
        ),
      ),
    );

    expect(find.text('Nâng cấp Pro'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('99.000đ'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('49.000đ'), findsOneWidget);
    expect(find.text('99.000đ'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Theo tháng'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Theo tháng'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pro-transfer-code')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final code = tester.widget<SelectableText>(
      find.byKey(const ValueKey('pro-transfer-code')),
    );
    expect(code.data, 'Nội dung CK: CVPRO-MONTHLY-USER1');
    expect(find.text('Quét mã để chuyển khoản'), findsOneWidget);
    // Without a configured receiving account the request button stays off.
    expect(
      find.byKey(const ValueKey('bank-transfer-unavailable')),
      findsOneWidget,
    );
    expect(find.text('owner@example.com'), findsOneWidget);
    expect(find.text('Tôi đã chuyển khoản'), findsOneWidget);
  });
}

Widget _appWithUser(AuthUser? user) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user)),
      billingRepositoryProvider.overrideWithValue(_FakeBilling()),
    ],
    child: const MaterialApp(home: ProUpgradeScreen()),
  );
}

class _FakeAuthRepository implements AuthRepository {
  const _FakeAuthRepository(this.user);

  final AuthUser? user;

  @override
  String get backendLabel => 'Test';

  @override
  AuthUser? get currentUser => user;

  @override
  bool get isConfigured => true;

  @override
  Stream<AuthSessionChange> watchSession() => const Stream.empty();

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
  Future<bool> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<SignUpResult> signUp({
    required String displayName,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthUser> updateDisplayName(String displayName) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> updatePassword(String password) =>
      throw UnimplementedError();
}

class _FakeBilling implements BillingRepository {
  @override
  Future<BillingStatus> fetchStatus() async =>
      const BillingStatus(isPro: false);

  @override
  Future<ProUpgradeRequest> submitRequest(ProPlan plan) =>
      throw UnimplementedError();
}
