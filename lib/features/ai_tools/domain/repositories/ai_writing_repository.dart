import '../models/summary_polish_request.dart';
import '../models/summary_polish_result.dart';

enum AiWritingFailureCode {
  notAuthenticated,
  invalidInput,
  rateLimited,
  quotaExceeded,
  unavailable,
  unknown,
}

class AiWritingFailure implements Exception {
  const AiWritingFailure(this.message, {required this.code, this.cause});

  final String message;
  final AiWritingFailureCode code;
  final Object? cause;

  @override
  String toString() => 'AiWritingFailure($code): $message';
}

abstract interface class AiWritingRepository {
  Future<SummaryPolishResult> polishSummary(SummaryPolishRequest request);
}
