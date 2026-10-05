import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized Environment Variables Helper (with safe initialization checks)
class EnvConstants {
  static String get supabaseUrl {
    if (!dotenv.isInitialized) return '';
    return dotenv.get('SUPABASE_URL', fallback: '');
  }

  static String get supabaseAnonKey {
    if (!dotenv.isInitialized) return '';
    return dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  }

  static String get geminiApiKey {
    if (!dotenv.isInitialized) return '';
    return dotenv.get('GEMINI_API_KEY', fallback: '');
  }

  static String get groqApiKey {
    if (!dotenv.isInitialized) return '';
    return dotenv.get('GROQ_API_KEY', fallback: '');
  }

  /// Checks if Supabase credentials are valid (not empty and not sample placeholders)
  static bool get isSupabaseConfigured {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) return false;
    if (supabaseUrl.contains('your-project-id')) return false;
    if (supabaseAnonKey.contains('your-anon-public-key')) return false;
    return true;
  }

  /// Checks if Gemini AI key is configured
  static bool get isGeminiConfigured {
    if (geminiApiKey.isEmpty) return false;
    if (geminiApiKey.contains('YourGeminiApiKeyHere')) return false;
    return true;
  }
}
