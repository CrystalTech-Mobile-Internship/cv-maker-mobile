abstract final class AuthCallbackConstants {
  static const mobileScheme = 'com.example.cvmakermobile';
  static const mobileHost = 'login-callback';
  static const mobileUri = '$mobileScheme://$mobileHost';

  static bool isMobileCallback(Uri uri) =>
      uri.scheme == mobileScheme && uri.host == mobileHost;
}
