import 'package:cv_maker_mobile/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('expired email link lands on the recovery screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final router = createAppRouter(
      startInGuestMode: false,
      startAuthenticated: false,
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    router.go(
      '/error=access_denied&error_code=otp_expired'
      '&error_description=Email+link+is+invalid+or+has+expired',
    );
    await tester.pumpAndSettle();

    expect(find.text('Quên mật khẩu'), findsOneWidget);
    expect(find.byKey(const ValueKey('reset-link-error')), findsOneWidget);
  });
}
