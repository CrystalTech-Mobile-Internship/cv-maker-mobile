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
    label: 'Project chính',
    url: _value('SUPABASE_PRIMARY_URL'),
    anonKey: _value('SUPABASE_PRIMARY_ANON_KEY'),
  );

  static SupabaseEnvironment get _secondarySupabase => SupabaseEnvironment(
    name: 'secondary',
    label: 'Project phụ',
    url: _value('SUPABASE_SECONDARY_URL'),
    anonKey: _value('SUPABASE_SECONDARY_ANON_KEY'),
  );

  static SupabaseEnvironment get _legacySupabase => SupabaseEnvironment(
    name: 'legacy',
    label: 'Project mặc định',
    url: _value('SUPABASE_URL'),
    anonKey: _value('SUPABASE_ANON_KEY'),
  );

  /// Selects one backend for the entire app process. Auth sessions and user IDs
  /// are project-specific, so the app must never switch projects mid-session.
  static SupabaseEnvironment? get activeSupabaseEnvironment {
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

  static String get supabaseUrl => activeSupabaseEnvironment?.url ?? '';

  static String get supabaseAnonKey => activeSupabaseEnvironment?.anonKey ?? '';

  static String get supabaseProfileLabel =>
      activeSupabaseEnvironment?.label ?? 'Chưa cấu hình';

  /// Checks if Supabase credentials are valid (not empty and not sample placeholders)
  static bool get isSupabaseConfigured {
    return activeSupabaseEnvironment?.isConfigured ?? false;
  }
}
