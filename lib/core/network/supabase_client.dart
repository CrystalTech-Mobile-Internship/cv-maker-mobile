import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/env_constants.dart';

/// Helper to initialize and access Supabase
class SupabaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!EnvConstants.isSupabaseConfigured) {
      debugPrint(
        '⚠️ [SupabaseService] Supabase profile đang chọn chưa được cấu hình.\n'
        'Ứng dụng sẽ hoạt động ở chế độ Local / Offline Guest.',
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
      debugPrint(
        '✅ [SupabaseService] Đã khởi tạo ${EnvConstants.supabaseProfileLabel}.',
      );
    } catch (e) {
      debugPrint('❌ [SupabaseService] Lỗi khởi tạo Supabase: $e');
    }
  }

  /// Safe accessor to SupabaseClient (returns null if not initialized)
  static SupabaseClient? get client {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }

  static String get activeProfileLabel =>
      _initialized ? EnvConstants.supabaseProfileLabel : 'Không khả dụng';

  /// Throws a clear configuration error instead of returning a nullable client
  /// deep inside a data source.
  static SupabaseClient get requiredClient {
    final value = client;
    if (value == null) {
      throw StateError(
        'Supabase chưa được cấu hình. Kiểm tra profile và URL/key trong .env.',
      );
    }
    return value;
  }
}
