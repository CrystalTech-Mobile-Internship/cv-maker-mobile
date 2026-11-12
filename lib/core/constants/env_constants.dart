import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseEnvironment {
  const SupabaseEnvironment({
    required this.name,
    required this.label,
    required this.url,
    required this.anonKey,
  });

  final String name;
  final String label;
  final String url;
  final String anonKey;

  bool get isConfigured {
    if (url.isEmpty || anonKey.isEmpty) return false;
    if (url.contains('your-project-id')) return false;
    if (anonKey.contains('your-anon-public-key')) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }
}

/// Centralized Environment Variables Helper (with safe initialization checks)
class EnvConstants {
  static String _value(String name) {
    if (!dotenv.isInitialized) return '';
    return dotenv.get(name, fallback: '').trim();
  }

  static SupabaseEnvironment get _primarySupabase => SupabaseEnvironment(
    name: 'primary',
    label: 'Máy chủ chính',
    url: _value('SUPABASE_PRIMARY_URL'),
    anonKey: _value('SUPABASE_PRIMARY_ANON_KEY'),
  );

  static SupabaseEnvironment get _secondarySupabase => SupabaseEnvironment(
    name: 'secondary',
    label: 'Máy chủ phụ',
    url: _value('SUPABASE_SECONDARY_URL'),
    anonKey: _value('SUPABASE_SECONDARY_ANON_KEY'),
  );

  static SupabaseEnvironment get _legacySupabase => SupabaseEnvironment(
    name: 'legacy',
    label: 'Máy chủ',
    url: _value('SUPABASE_URL'),
    anonKey: _value('SUPABASE_ANON_KEY'),
  );

  static SupabaseEnvironment? _resolvedOverride;

  /// Set once at startup by the profile resolver when failover picked a
  /// different project than [preferredSupabaseEnvironment].
  static void useResolvedEnvironment(SupabaseEnvironment? environment) {
    _resolvedOverride = environment;
  }

  /// Project actually used by this app run.
  static SupabaseEnvironment? get activeSupabaseEnvironment =>
      _resolvedOverride ?? preferredSupabaseEnvironment;

  /// The other configured project, used only when the preferred one is
  /// unreachable at startup. Disable with `SUPABASE_FAILOVER=off`.
  static SupabaseEnvironment? get fallbackSupabaseEnvironment {
    if (_value('SUPABASE_FAILOVER').toLowerCase() == 'off') return null;
    final preferred = preferredSupabaseEnvironment;
    for (final candidate in [_primarySupabase, _secondarySupabase]) {
      if (candidate.isConfigured && candidate.name != preferred?.name) {
        return candidate;
      }
    }
    return null;
  }

  /// Selects one backend for the entire app process. Auth sessions and user IDs
  /// are project-specific, so the app must never switch projects mid-session.
  static SupabaseEnvironment? get preferredSupabaseEnvironment {
    final requested = _value('SUPABASE_ACTIVE_PROFILE').toLowerCase();
    if (requested == 'primary') return _primarySupabase;
    if (requested == 'secondary') return _secondarySupabase;

    // Backward compatibility for existing one-project .env files.
    final legacy = _legacySupabase;
    if (legacy.isConfigured) return legacy;
    final primary = _primarySupabase;
    if (primary.isConfigured) return primary;
    final secondary = _secondarySupabase;
    if (secondary.isConfigured) return secondary;
    return null;
  }

  /// Shows the "enter recovery code" option. Enable only when the reset
  /// email template includes `{{ .Token }}` (requires custom SMTP on the
  /// Supabase Free plan).
  static bool get recoveryCodeInEmail =>
      _value('AUTH_RECOVERY_CODE_IN_EMAIL').toLowerCase() == 'true';

  static String get supabaseUrl => activeSupabaseEnvironment?.url ?? '';

  static String get supabaseAnonKey => activeSupabaseEnvironment?.anonKey ?? '';

  static String get supabaseProfileLabel =>
      activeSupabaseEnvironment?.label ?? 'Chưa kết nối';

  /// Checks if Supabase credentials are valid (not empty and not sample placeholders)
  static bool get isSupabaseConfigured {
    return activeSupabaseEnvironment?.isConfigured ?? false;
  }
}
