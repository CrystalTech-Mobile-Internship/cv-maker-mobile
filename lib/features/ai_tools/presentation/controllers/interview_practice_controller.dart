import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cv_editor/domain/models/cv_model.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../../domain/services/cv_plain_text.dart';
import 'ai_assistant_providers.dart';

class InterviewPracticeState {
  const InterviewPracticeState({
    this.questions = const [],
    this.index = 0,
    this.answers = const {},
    this.feedback = const {},
    this.isLoadingQuestions = false,
    this.isEvaluating = false,
    this.errorMessage,
    this.errorCode,
  });

  final List<AiInterviewQuestion> questions;
  final int index;
  final Map<int, String> answers;
  final Map<int, AiAnswerFeedback> feedback;
  final bool isLoadingQuestions;
  final bool isEvaluating;
  final String? errorMessage;
  final AiWritingFailureCode? errorCode;

  bool get hasQuestions => questions.isNotEmpty;
  bool get isBusy => isLoadingQuestions || isEvaluating;
  AiInterviewQuestion? get current => hasQuestions ? questions[index] : null;

  /// Average score of answered questions, or null when none were scored.
  double? get averageScore {
    if (feedback.isEmpty) return null;
    final total = feedback.values.fold<int>(0, (sum, f) => sum + f.score);
    return total / feedback.length;
  }

  InterviewPracticeState copyWith({
    List<AiInterviewQuestion>? questions,
    int? index,
    Map<int, String>? answers,
    Map<int, AiAnswerFeedback>? feedback,
    bool? isLoadingQuestions,
    bool? isEvaluating,
    String? errorMessage,
    AiWritingFailureCode? errorCode,
    bool clearError = false,
  }) {
    return InterviewPracticeState(
      questions: questions ?? this.questions,
      index: index ?? this.index,
      answers: answers ?? this.answers,
      feedback: feedback ?? this.feedback,
      isLoadingQuestions: isLoadingQuestions ?? this.isLoadingQuestions,
      isEvaluating: isEvaluating ?? this.isEvaluating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
    );
  }
}

/// Mock interview: AI asks questions based on the CV (and JD), the user
/// answers, and the AI scores each answer with concrete advice.
class InterviewPracticeController
    extends StateNotifier<InterviewPracticeState> {
  InterviewPracticeController(this._repository)
    : super(const InterviewPracticeState());

  final AiAssistantRepository _repository;

  Future<void> start(CvModel cv, {String jobDescription = ''}) async {
    if (state.isBusy) return;
    state = const InterviewPracticeState(isLoadingQuestions: true);
    try {
      final questions = await _repository.interviewQuestions(
        cvText: cvPlainText(cv),
        jobDescription: jobDescription.trim(),
        language: cv.language,
      );
      if (!mounted) return;
      state = state.copyWith(questions: questions, isLoadingQuestions: false);
    } on AiWritingFailure catch (failure) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingQuestions: false,
        errorMessage: failure.message,
        errorCode: failure.code,
      );
    }
  }

  void updateAnswer(String text) {
    state = state.copyWith(answers: {...state.answers, state.index: text});
  }

  Future<void> evaluate(CvModel cv) async {
    final question = state.current;
    final answer = (state.answers[state.index] ?? '').trim();
    if (question == null || state.isBusy) return;
    if (answer.length < 15) {
      state = state.copyWith(
        errorMessage: 'Hãy trả lời chi tiết hơn (ít nhất 15 ký tự).',
        errorCode: AiWritingFailureCode.invalidInput,
      );
      return;
    }
    final index = state.index;
    state = state.copyWith(isEvaluating: true, clearError: true);
    try {
      final result = await _repository.answerFeedback(
        question: question.question,
        answer: answer,
        cvText: cvPlainText(cv, maxLength: 4000),
        language: cv.language,
      );
      if (!mounted) return;
      state = state.copyWith(
        isEvaluating: false,
        feedback: {...state.feedback, index: result},
      );
    } on AiWritingFailure catch (failure) {
      if (!mounted) return;
      state = state.copyWith(
        isEvaluating: false,
        errorMessage: failure.message,
        errorCode: failure.code,
      );
    }
  }

  void goTo(int index) {
    if (index < 0 || index >= state.questions.length || state.isBusy) return;
    state = state.copyWith(index: index, clearError: true);
  }

  void dismissError() => state = state.copyWith(clearError: true);
}

final interviewPracticeControllerProvider =
    StateNotifierProvider.autoDispose<
      InterviewPracticeController,
      InterviewPracticeState
    >(
      (ref) =>
          InterviewPracticeController(ref.watch(aiAssistantRepositoryProvider)),
    );
