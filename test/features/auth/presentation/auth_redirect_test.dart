import 'package:cv_maker_mobile/features/auth/presentation/auth_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only allows known internal post-auth destinations', () {
    expect(safeAuthRedirect('/upgrade-pro'), '/upgrade-pro');
    expect(safeAuthRedirect('https://example.com'), isNull);
    expect(safeAuthRedirect('//example.com'), isNull);
    expect(safeAuthRedirect('/unknown'), isNull);
  });

  test('builds auth entry URL with an encoded safe redirect', () {
    expect(
      authEntryLocation('/login', '/upgrade-pro'),
      '/login?redirect=%2Fupgrade-pro',
    );
    expect(authEntryLocation('/login', 'https://example.com'), '/login');
  });
}
