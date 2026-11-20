import 'package:flutter/foundation.dart';
import '../i18n/app_language.dart';

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
      return tr(
        'Liên kết đã hết hạn hoặc đã được dùng. Hãy gửi lại liên kết mới.',
        'This link has expired or was already used. Please request a new one.',
      );
    case 'access_denied':
      return tr(
        'Liên kết không hợp lệ. Hãy gửi lại liên kết mới.',
        'This link is not valid. Please request a new one.',
      );
    default:
      return tr(
        'Không mở được liên kết khôi phục. Hãy mở liên kết trên chính '
            'thiết bị và trình duyệt đã gửi yêu cầu, hoặc gửi lại liên kết mới.',
        'Could not open the reset link. Open it on the same device and browser you used to ask for it, or request a new one.',
      );
  }
}

/// True when [uri] carries access/PKCE tokens from an OAuth callback
/// (and is not a password recovery redirect).
bool isOAuthCallbackUri(Uri uri) {
  final callback = parseAuthCallback(uri);
  return callback.hasTokens && !callback.isRecovery;
}

bool _initialOAuthCallback = isOAuthCallbackUri(Uri.base);

/// True when the current launch originated from an OAuth redirect callback.
bool get isInitialOAuthCallback => _initialOAuthCallback;

/// Marks the initial OAuth callback as handled so subsequent checks
/// do not treat restored sessions as fresh sign-ins.
void markInitialOAuthCallbackHandled() {
  _initialOAuthCallback = false;
}

@visibleForTesting
void setInitialOAuthCallbackForTest(bool value) {
  _initialOAuthCallback = value;
}
