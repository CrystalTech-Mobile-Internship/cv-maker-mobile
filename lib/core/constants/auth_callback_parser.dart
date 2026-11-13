/// Parameters Supabase appends when it redirects back from an email link
/// (password recovery, sign-up confirmation) or OAuth.
class AuthCallbackInfo {
  const AuthCallbackInfo({
    this.type,
    this.errorCode,
    this.errorDescription,
    this.hasTokens = false,
  });

  final String? type;
  final String? errorCode;
  final String? errorDescription;

  /// True when the URL carries an access token or a PKCE code.
  final bool hasTokens;

  bool get isRecovery => type == 'recovery';
  bool get hasError => errorCode != null || errorDescription != null;
  bool get isCallback => hasError || hasTokens || type != null;
}

/// Reads auth callback parameters from the query, the fragment and the
/// path. With Flutter's hash URL strategy the `#error=...` fragment that
/// Supabase appends ends up in the route path, so all three are checked.
AuthCallbackInfo parseAuthCallback(Uri uri) {
  final params = <String, String>{};
  final sources = [uri.query, uri.fragment, Uri.decodeFull(uri.path)];
  for (final source in sources) {
    for (final part in source.split(RegExp(r'[&?#/]'))) {
      final index = part.indexOf('=');
      if (index <= 0) continue;
      final key = part.substring(0, index);
      final value = part.substring(index + 1);
      try {
        params[key] = Uri.decodeQueryComponent(value);
      } catch (_) {
        params[key] = value;
      }
    }
  }
  String? read(String key) {
    final value = params[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  return AuthCallbackInfo(
    type: read('type'),
    errorCode: read('error_code') ?? read('error'),
    errorDescription: read('error_description'),
    hasTokens: read('access_token') != null || read('code') != null,
  );
}

/// User-facing explanation for a failed email link.
String describeAuthLinkError(String? code) {
  switch (code) {
    case 'otp_expired':
      return 'Liên kết đã hết hạn hoặc đã được dùng. Hãy gửi lại liên kết mới.';
    case 'access_denied':
      return 'Liên kết không hợp lệ. Hãy gửi lại liên kết mới.';
    default:
      return 'Không mở được liên kết khôi phục. Hãy mở liên kết trên chính '
          'thiết bị và trình duyệt đã gửi yêu cầu, hoặc gửi lại liên kết mới.';
  }
}
