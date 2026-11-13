import 'dart:async';

import 'package:http/http.dart' as http;

import '../constants/env_constants.dart';

typedef SupabaseHealthProbe = Future<bool> Function(SupabaseEnvironment env);

class SupabaseResolution {
  const SupabaseResolution(this.environment, {this.usedFallback = false});

  final SupabaseEnvironment? environment;
  final bool usedFallback;
}

/// Picks the Supabase project for this app run. The preferred profile is
/// used unless it is unreachable and a configured fallback answers. The
/// choice is made once at startup: auth sessions are project-specific, so
/// the app never switches projects mid-session.
abstract final class SupabaseProfileResolver {
  static Future<SupabaseResolution> resolve({
    required SupabaseEnvironment? preferred,
    SupabaseEnvironment? fallback,
    required SupabaseHealthProbe probe,
  }) async {
    if (preferred == null || !preferred.isConfigured) {
      if (fallback != null && fallback.isConfigured) {
        return SupabaseResolution(fallback, usedFallback: true);
      }
      return const SupabaseResolution(null);
    }
    if (fallback == null || !fallback.isConfigured) {
      return SupabaseResolution(preferred);
    }
    if (await _safeProbe(probe, preferred)) {
      return SupabaseResolution(preferred);
    }
    if (await _safeProbe(probe, fallback)) {
      return SupabaseResolution(fallback, usedFallback: true);
    }
    // Both unreachable (e.g. offline): keep the preferred project so the
    // stored session stays valid once the network returns.
    return SupabaseResolution(preferred);
  }

  static Future<bool> _safeProbe(
    SupabaseHealthProbe probe,
    SupabaseEnvironment env,
  ) async {
    try {
      return await probe(env);
    } catch (_) {
      return false;
    }
  }

  /// Calls the public Auth health endpoint with the publishable key.
  static Future<bool> httpHealthProbe(
    SupabaseEnvironment env, {
    Duration timeout = const Duration(seconds: 3),
    http.Client? client,
  }) async {
    final owned = client == null;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(
            Uri.parse('${env.url}/auth/v1/health'),
            headers: {'apikey': env.anonKey},
          )
          .timeout(timeout);
      return response.statusCode < 500;
    } finally {
      if (owned) httpClient.close();
    }
  }
}
