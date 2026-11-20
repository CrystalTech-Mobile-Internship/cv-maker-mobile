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
    expect(find.text('Đăng nhập để nâng cấp'), findsOneWidget);
    expect(find.byKey(const ValueKey('pro-start-checkout')), findsNothing);
  });

  testWidgets('starting a checkout shows the transfer note, not the email', (
    tester,
  ) async {
    final billing = _FakeBilling();
    await tester.pumpWidget(
      _appWithUser(
        const AuthUser(
          id: 'user-1',
          email: 'owner@example.com',
          displayName: 'Owner',
          provider: 'email',
          isEmailConfirmed: true,
        ),
        billing: billing,
      ),
    );

    expect(find.text('49.000đ'), findsOneWidget);
    expect(find.text('119.000đ'), findsOneWidget);
    expect(find.text('Tiết kiệm 19%'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pro-plan-monthly')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('pro-start-checkout')));
    await tester.pump();
    await tester.pump();

    expect(billing.started, [ProPlan.monthly]);
    expect(find.byKey(const ValueKey('pro-checkout')), findsOneWidget);
    // No receiving account in tests: payment shows as paused.
    expect(
      find.byKey(const ValueKey('bank-transfer-unavailable')),
      findsOneWidget,
    );
    expect(find.text('owner@example.com'), findsNothing);
    // Stop the payment check timer before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Pro accounts see their plan instead of prices', (tester) async {
    await tester.pumpWidget(
      _appWithUser(
        const AuthUser(
          id: 'user-1',
          email: 'owner@example.com',
          displayName: 'Owner',
          provider: 'email',
          isEmailConfirmed: true,
        ),
        billing: _FakeBilling(isPro: true),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('pro-active')), findsOneWidget);
    expect(find.byKey(const ValueKey('pro-start-checkout')), findsNothing);
  });
}

Widget _appWithUser(AuthUser? user, {_FakeBilling? billing}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user)),
      billingRepositoryProvider.overrideWithValue(billing ?? _FakeBilling()),
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
  _FakeBilling({this.isPro = false});

  final bool isPro;
  final started = <ProPlan>[];

  @override
  Future<BillingStatus> fetchStatus() async => BillingStatus(isPro: isPro);

  @override
  Future<ProUpgradeRequest> startCheckout(ProPlan plan) async {
    started.add(plan);
    return ProUpgradeRequest(
      id: 'r1',
      plan: plan,
      transferCode: 'CVPROMUSER1234',
      status: ProRequestStatus.pending,
      createdAt: DateTime.utc(2026, 11, 20),
      amount: plan.amount,
    );
  }
}
