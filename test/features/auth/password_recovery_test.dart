import 'package:cv_maker_mobile/app/routes.dart';
import 'package:cv_maker_mobile/core/constants/auth_callback_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAuthCallback', () {
    test('reads an expired-link error from the hash route', () {
      final info = parseAuthCallback(
        Uri.parse(
          'http://localhost:8101/#error=access_denied&error_code=otp_expired'
          '&error_description=Email+link+is+invalid+or+has+expired',
        ),
      );
      expect(info.hasError, isTrue);
      expect(info.errorCode, 'otp_expired');
      expect(info.errorDescription, 'Email link is invalid or has expired');
    });

    test('recognises a recovery redirect with tokens', () {
      final info = parseAuthCallback(
        Uri.parse('http://localhost/#access_token=abc&type=recovery'),
      );
      expect(info.isRecovery, isTrue);
      expect(info.hasTokens, isTrue);
    });

    test('ignores ordinary app routes', () {
      expect(parseAuthCallback(Uri.parse('/home')).isCallback, isFalse);
    });
  });

  group('redirectForAppUri', () {
    test('sends failed email links to the recovery screen with a reason', () {
      expect(
        redirectForAppUri(
          Uri.parse('/error=access_denied&error_code=otp_expired'),
        ),
        '/forgot-password?link_error=otp_expired',
      );
    });

    test('opens the new-password screen for recovery redirects', () {
      expect(
        redirectForAppUri(Uri.parse('/access_token=abc&type=recovery')),
        '/reset-password',
      );
    });

    test('does not loop on the recovery screen itself', () {
      expect(
        redirectForAppUri(Uri.parse('/forgot-password?link_error=otp_expired')),
        isNull,
      );
    });

    test('keeps the root redirect to home', () {
      expect(redirectForAppUri(Uri.parse('/')), '/home');
    });
  });

  test('explains link errors in plain language', () {
    expect(describeAuthLinkError('otp_expired'), contains('hết hạn'));
    expect(describeAuthLinkError('pkce'), contains('trình duyệt'));
  });
}
