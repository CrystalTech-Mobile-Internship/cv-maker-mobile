import 'package:cv_maker_mobile/app/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile OAuth callback redirects to home', () {
    expect(
      redirectForAppUri(
        Uri.parse('com.example.cvmakermobile://login-callback/?code=test-code'),
      ),
      '/home',
    );
  });

  test('root location redirects to home instead of an error page', () {
    expect(redirectForAppUri(Uri.parse('/')), '/home');
  });
}
