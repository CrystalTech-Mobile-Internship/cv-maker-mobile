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

  Future<void> polish(SummaryPolishRequest request) async {
    if (state.isLoading) return;
    state = const SummaryPolishState(status: SummaryPolishStatus.loading);
    try {
      final result = await _repository.polishSummary(request);
      state = SummaryPolishState(
        status: SummaryPolishStatus.success,
        suggestedSummary: result.suggestedSummary,
        provider: result.provider,
      );
    } on AiWritingFailure catch (error) {
      state = SummaryPolishState(
        status: SummaryPolishStatus.failure,
        errorMessage: error.message,
      );
    } catch (_) {
      state = const SummaryPolishState(
        status: SummaryPolishStatus.failure,
        errorMessage: 'Không thể sử dụng AI lúc này. Hãy thử lại sau.',
      );
    }
  }

  void reset() => state = const SummaryPolishState();
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
