import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/summary_polish_request.dart';
import '../../../../core/i18n/app_language.dart';

/// Name of the single Edge Function that fronts every AI capability. The AI
/// provider key lives only in that function's secrets.
const cvAssistantFunctionName = 'cv-assistant';

class AiWritingRemoteException implements Exception {
  const AiWritingRemoteException(
    this.message, {
    required this.statusCode,
    this.code,
    this.quota,
    this.cause,
  });

  final String message;
  final int statusCode;
  final String? code;
  final Map<String, dynamic>? quota;
  final Object? cause;

  @override
  String toString() => 'AiWritingRemoteException($statusCode, $code)';
}

class AiWritingRemoteDataSource {
  AiWritingRemoteDataSource({SupabaseClient? client})
    : _providedClient = client;

  final SupabaseClient? _providedClient;

  SupabaseClient get _client =>
      _providedClient ?? SupabaseService.requiredClient;

  /// Calls one `cv-assistant` action and returns `{result, quota, model}`.
  Future<Map<String, dynamic>> invoke(
    String action,
    Map<String, dynamic> input,
  ) async {
    final SupabaseClient client;
    try {
      client = _client;
    } on StateError {
      throw AiWritingRemoteException(
        tr(
          'Chức năng này tạm thời chưa dùng được.',
          'This feature is not available right now.',
        ),
        statusCode: 503,
        code: 'not_configured',
      );
    }
    if (client.auth.currentSession == null) {
      throw AiWritingRemoteException(
        tr(
          'Bạn cần đăng nhập để dùng chức năng này.',
          'Please sign in to use this feature.',
        ),
        statusCode: 401,
        code: 'unauthenticated',
      );
    }

    try {
      final response = await client.functions.invoke(
        cvAssistantFunctionName,
        body: {'action': action, 'input': input},
      );
      final data = response.data;
      if (response.status < 200 || response.status >= 300) {
        throw _fromBody(data, response.status);
      }
      if (data is! Map) {
        throw AiWritingRemoteException(
          tr(
            'Có lỗi xảy ra. Hãy thử lại.',
            'Something went wrong. Please try again.',
          ),
          statusCode: 502,
        );
      }
      return Map<String, dynamic>.from(data);
    } on AiWritingRemoteException {
      rethrow;
    } on FunctionException catch (error) {
      throw _fromBody(error.details, error.status, cause: error);
    } catch (error) {
      throw AiWritingRemoteException(
        tr(
          'Không có kết nối. Hãy kiểm tra mạng.',
          'No connection. Please check your network.',
        ),
        statusCode: 503,
        cause: error,
      );
    }
  }

  Future<Map<String, dynamic>> polishSummary(
    SummaryPolishRequest request,
  ) async {
    final data = await invoke('polish_summary', request.toJson());
    final result = data['result'];
    return {
      'suggestedSummary': result is Map ? result['suggestedSummary'] : null,
      'provider': data['model'] ?? 'ai',
      'quota': data['quota'],
    };
  }

  static AiWritingRemoteException _fromBody(
    Object? value,
    int status, {
    Object? cause,
  }) {
    final body = value is Map ? value : const {};
    final message = body['message'] is String
        ? body['message'] as String
        : status == 404
        ? tr(
            'Chức năng này tạm thời chưa dùng được.',
            'This feature is not available right now.',
          )
        : tr(
            'Hệ thống đang bận. Hãy thử lại sau.',
            'The service is busy. Please try again later.',
          );
    return AiWritingRemoteException(
      message,
      statusCode: status,
      code: body['code'] as String?,
      quota: body['quota'] is Map
          ? Map<String, dynamic>.from(body['quota'] as Map)
          : null,
      cause: cause,
    );
  }
}
