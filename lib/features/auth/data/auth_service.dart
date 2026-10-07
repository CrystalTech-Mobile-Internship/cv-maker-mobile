import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';

/// Thin authentication layer used by the login screen.
///
/// Keeping Supabase calls here prevents widgets from depending directly on
/// the SDK and gives us one place to add auth-related behavior later.
class AuthService {
  static const googleRedirectUri =
      'com.example.cv_maker_mobile://login-callback';

  SupabaseClient get _client => SupabaseService.requiredClient;

  User? get currentUser => SupabaseService.client?.auth.currentUser;

  Session? get currentSession => SupabaseService.client?.auth.currentSession;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      // Web must return to the origin that is actually serving Flutter.
      // Android uses the registered custom deep link instead.
      redirectTo: kIsWeb ? Uri.base.origin : googleRedirectUri,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }
}
