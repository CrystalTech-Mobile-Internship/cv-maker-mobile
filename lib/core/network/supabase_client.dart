import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/env_constants.dart';

/// Helper to initialize and access Supabase
class SupabaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (!EnvConstants.isSupabaseConfigured) {
      debugPrint(
        '⚠️ [SupabaseService] SUPABASE_URL hoặc SUPABASE_ANON_KEY chưa được cấu hình thực tế.\n'
        'Ứng dụng sẽ hoạt động ở chế độ Local / Offline Guest cho đến khi nhận key từ Phong.',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: EnvConstants.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: EnvConstants.supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('✅ [SupabaseService] Supabase đã khởi tạo thành công.');
    } catch (e) {
      debugPrint('❌ [SupabaseService] Lỗi khởi tạo Supabase: $e');
    }
  }

  /// Safe accessor to SupabaseClient (returns null if not initialized)
  static SupabaseClient? get client {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }
}
