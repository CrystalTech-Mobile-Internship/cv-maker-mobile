import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/ai_writing_remote_data_source.dart';
import '../../data/repositories/supabase_ai_writing_repository.dart';
import '../../domain/models/summary_polish_request.dart';
import '../../domain/repositories/ai_writing_repository.dart';

enum SummaryPolishStatus { idle, loading, success, failure }

class SummaryPolishState {
  const SummaryPolishState({
    this.status = SummaryPolishStatus.idle,
    this.suggestedSummary,
    this.provider,
    this.errorMessage,
  });

  final SummaryPolishStatus status;
  final String? suggestedSummary;
  final String? provider;
  final String? errorMessage;

  bool get isLoading => status == SummaryPolishStatus.loading;
}

class SummaryPolishController extends StateNotifier<SummaryPolishState> {
  SummaryPolishController(this._repository) : super(const SummaryPolishState());

  final AiWritingRepository _repository;
  Future<SummaryPolishState>? _inFlight;

  Future<SummaryPolishState> polish(SummaryPolishRequest request) {
    final activeRequest = _inFlight;
    if (activeRequest != null) return activeRequest;

    late final Future<SummaryPolishState> operation;
    operation = _performPolish(request).whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
    _inFlight = operation;
    return operation;
  }

  Future<SummaryPolishState> _performPolish(
    SummaryPolishRequest request,
  ) async {
    state = const SummaryPolishState(status: SummaryPolishStatus.loading);
    try {
      final result = await _repository.polishSummary(request);
      final nextState = SummaryPolishState(
        status: SummaryPolishStatus.success,
        suggestedSummary: result.suggestedSummary,
        provider: result.provider,
      );
      if (mounted) state = nextState;
      return nextState;
    } on AiWritingFailure catch (error) {
      final nextState = SummaryPolishState(
        status: SummaryPolishStatus.failure,
        errorMessage: error.message,
      );
      if (mounted) state = nextState;
      return nextState;
    } catch (_) {
      const nextState = SummaryPolishState(
        status: SummaryPolishStatus.failure,
        errorMessage: 'Không thể sử dụng AI lúc này. Hãy thử lại sau.',
      );
      if (mounted) state = nextState;
      return nextState;
    }
  }

  void reset() {
    if (_inFlight != null) return;
    if (mounted) state = const SummaryPolishState();
  }
}

final aiWritingRemoteDataSourceProvider = Provider<AiWritingRemoteDataSource>(
  (ref) => AiWritingRemoteDataSource(),
);

final aiWritingRepositoryProvider = Provider<AiWritingRepository>(
  (ref) =>
      SupabaseAiWritingRepository(ref.watch(aiWritingRemoteDataSourceProvider)),
);

final summaryPolishControllerProvider =
    StateNotifierProvider.autoDispose<
      SummaryPolishController,
      SummaryPolishState
    >((ref) => SummaryPolishController(ref.watch(aiWritingRepositoryProvider)));
