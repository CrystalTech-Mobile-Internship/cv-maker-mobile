import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/env_constants.dart';
import 'supabase_profile_resolver.dart';

/// Helper to initialize and access Supabase
class SupabaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static bool _usingFallback = false;

  /// True when the preferred project was unreachable and the mirror project
  /// was selected for this run.
  static bool get isUsingFallback => _usingFallback;

  static Future<void> initialize({SupabaseHealthProbe? probe}) async {
    if (_initialized) return;

    final resolution = await SupabaseProfileResolver.resolve(
      preferred: EnvConstants.preferredSupabaseEnvironment,
      fallback: EnvConstants.fallbackSupabaseEnvironment,
      probe: probe ?? SupabaseProfileResolver.httpHealthProbe,
    );
    _usingFallback = resolution.usedFallback;
    if (resolution.usedFallback) {
      EnvConstants.useResolvedEnvironment(resolution.environment);
      debugPrint(
        '⚠️ [SupabaseService] Project ưu tiên không phản hồi, '
        'chuyển sang ${resolution.environment?.label}.',
      );
    }

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

  static String get activeProfileLabel => !_initialized
      ? 'Không khả dụng'
      : _usingFallback
      ? '${EnvConstants.supabaseProfileLabel} (dự phòng)'
      : EnvConstants.supabaseProfileLabel;

  /// Throws a clear configuration error instead of returning a nullable client
  /// deep inside a data source.
  static SupabaseClient get requiredClient {
    final value = client;
    if (value == null) {
      throw StateError('Chưa kết nối được máy chủ. Hãy thử lại sau.');
    }
    return value;
  }
}
