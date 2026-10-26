import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/summary_polish_request.dart';

class AiWritingRemoteException implements Exception {
  const AiWritingRemoteException(
    this.message, {
    required this.statusCode,
    this.cause,
  });

  final String message;
  final int statusCode;
  final Object? cause;
}

class AiWritingRemoteDataSource {
  AiWritingRemoteDataSource({SupabaseClient? client})
    : _providedClient = client;

  final SupabaseClient? _providedClient;

  SupabaseClient get _client =>
      _providedClient ?? SupabaseService.requiredClient;

  Future<Map<String, dynamic>> polishSummary(
    SummaryPolishRequest request,
  ) async {
    if (_client.auth.currentSession == null) {
      throw const AiWritingRemoteException(
        'Bạn cần đăng nhập để sử dụng trợ lý AI.',
        statusCode: 401,
      );
    }

    try {
      final response = await _client.functions.invoke(
        'polish-summary',
        body: request.toJson(),
      );
      if (response.status < 200 || response.status >= 300) {
        throw AiWritingRemoteException(
          _messageFrom(response.data),
          statusCode: response.status,
        );
      }
      final data = response.data;
      if (data is! Map) {
        throw const AiWritingRemoteException(
          'Dịch vụ AI trả về dữ liệu không hợp lệ.',
          statusCode: 502,
        );
      }
      return Map<String, dynamic>.from(data);
    } on AiWritingRemoteException {
      rethrow;
    } on FunctionException catch (error) {
      throw AiWritingRemoteException(
        _messageFrom(error.details),
        statusCode: error.status,
        cause: error,
      );
    } catch (error) {
      throw AiWritingRemoteException(
        'Không thể kết nối trợ lý AI. Hãy kiểm tra mạng và thử lại.',
        statusCode: 503,
        cause: error,
      );
    }
  }

  static String _messageFrom(Object? value) {
    if (value is Map && value['message'] is String) {
      return value['message'] as String;
    }
    return 'Dịch vụ AI tạm thời không khả dụng.';
  }
}
