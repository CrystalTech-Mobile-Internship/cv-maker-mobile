import 'dart:async';

import '../../domain/models/summary_polish_request.dart';
import '../../domain/models/summary_polish_result.dart';
import '../../domain/repositories/ai_writing_repository.dart';
import '../datasources/ai_writing_remote_data_source.dart';

class SupabaseAiWritingRepository implements AiWritingRepository {
  SupabaseAiWritingRepository(
    this._remoteDataSource, {
    Duration timeout = const Duration(seconds: 30),
  }) : _timeout = timeout;

  final AiWritingRemoteDataSource _remoteDataSource;
  final Duration _timeout;

  @override
  Future<SummaryPolishResult> polishSummary(
    SummaryPolishRequest request,
  ) async {
    try {
      final data = await _remoteDataSource
          .polishSummary(request)
          .timeout(_timeout);
      final suggested = data['suggestedSummary']?.toString().trim() ?? '';
      if (suggested.isEmpty) {
        throw const AiWritingFailure(
          'AI chưa tạo được nội dung phù hợp. Hãy thử lại.',
          code: AiWritingFailureCode.unavailable,
        );
      }
      return SummaryPolishResult(
        suggestedSummary: suggested,
        provider: data['provider']?.toString() ?? 'ai',
      );
    } on AiWritingFailure {
      rethrow;
    } on AiWritingRemoteException catch (error) {
      if (error.statusCode == 404) {
        throw AiWritingFailure(
          'Trợ lý AI chưa được kích hoạt trên máy chủ. Hãy thử lại sau.',
          code: AiWritingFailureCode.unavailable,
          cause: error,
        );
      }
      throw AiWritingFailure(
        error.message,
        code: _codeFor(error.statusCode),
        cause: error,
      );
    } on TimeoutException catch (error) {
      throw AiWritingFailure(
        'AI phản hồi quá lâu. Hãy thử lại sau.',
        code: AiWritingFailureCode.unavailable,
        cause: error,
      );
    }
  }

  AiWritingFailureCode _codeFor(int status) => aiFailureCodeForStatus(status);
}

AiWritingFailureCode aiFailureCodeForStatus(int status) {
  if (status == 402) return AiWritingFailureCode.quotaExceeded;
  if (status == 413) return AiWritingFailureCode.invalidInput;
  if (status == 401) return AiWritingFailureCode.notAuthenticated;
  if (status == 400 || status == 422) {
    return AiWritingFailureCode.invalidInput;
  }
  if (status == 429) return AiWritingFailureCode.rateLimited;
  if (status >= 500) return AiWritingFailureCode.unavailable;
  return AiWritingFailureCode.unknown;
}
