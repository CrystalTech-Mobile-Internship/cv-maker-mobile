import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/auth_callback_constants.dart';
import '../../../../core/network/supabase_client.dart';

class SupabaseAuthDataSource {
  SupabaseAuthDataSource({SupabaseClient? client}) : _providedClient = client;

  static const callbackUri = AuthCallbackConstants.mobileUri;

  final SupabaseClient? _providedClient;

  SupabaseClient? get optionalClient =>
      _providedClient ?? SupabaseService.client;

  SupabaseClient get requiredClient {
    final client = optionalClient;
    if (client == null) {
      throw StateError(
        'Supabase chưa được cấu hình. Hãy kiểm tra SUPABASE_URL và '
        'SUPABASE_ANON_KEY.',
      );
    }
    return client;
  }

  User? get currentUser => optionalClient?.auth.currentUser;

  String get backendLabel => SupabaseService.activeProfileLabel;

  Stream<AuthState> watchAuthState() {
    final client = optionalClient;
    if (client == null) return const Stream<AuthState>.empty();
    return client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return requiredClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String displayName,
    required String email,
    required String password,
  }) {
    return requiredClient.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName, 'full_name': displayName},
    );
  }

  Future<bool> signInWithGoogle() {
    return requiredClient.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : callbackUri,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  Future<void> requestPasswordReset(String email) {
    return requiredClient.auth.resetPasswordForEmail(
      email,
      // The auth event routes to /reset-password after Supabase restores the
      // recovery session. Returning to the origin avoids requiring a server
      // rewrite rule for a nested Flutter Web route.
      redirectTo: kIsWeb ? Uri.base.origin : callbackUri,
    );
  }

  Future<UserResponse> updatePassword(String password) {
    return requiredClient.auth.updateUser(UserAttributes(password: password));
  }

  Future<UserResponse> updateDisplayName(String displayName) {
    return requiredClient.auth.updateUser(
      UserAttributes(
        data: {
          'display_name': displayName,
          // Kept for compatibility with the alternate development schema.
          'full_name': displayName,
        },
      ),
    );
  }

  Future<void> signOut() => requiredClient.auth.signOut();
}
