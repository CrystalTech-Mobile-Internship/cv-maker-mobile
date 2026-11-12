import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../resume_import/domain/models/resume_import_draft.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import 'ai_assistant_providers.dart';

const _maxUserMessageLength = 1500;

class AiInterviewState {
  const AiInterviewState({
    required this.language,
    required this.messages,
    this.isSending = false,
    this.isGenerating = false,
    this.progress = 0,
    this.readyToGenerate = false,
    this.errorMessage,
    this.errorCode,
  });

  factory AiInterviewState.initial(String language) => AiInterviewState(
    language: language,
    messages: [
      AiChatMessage(
        role: AiChatRole.assistant,
        content: language == 'en'
            ? 'Hi! I will ask a few questions to build your CV. Which position are you applying for, and how much experience do you have?'
            : 'Chào bạn! Mình sẽ hỏi vài câu để cùng bạn tạo CV. Bạn đang muốn ứng tuyển vị trí nào và đã có bao nhiêu kinh nghiệm?',
      ),
    ],
  );

  final String language;
  final List<AiChatMessage> messages;
  final bool isSending;
  final bool isGenerating;
  final int progress;
  final bool readyToGenerate;
  final String? errorMessage;
  final AiWritingFailureCode? errorCode;

  bool get isBusy => isSending || isGenerating;

  int get userTurns =>
      messages.where((message) => message.role == AiChatRole.user).length;

  /// Users may generate early once they have shared a few answers.
  bool get canGenerate => !isBusy && (readyToGenerate || userTurns >= 3);

  AiInterviewState copyWith({
    String? language,
    List<AiChatMessage>? messages,
    bool? isSending,
    bool? isGenerating,
    int? progress,
    bool? readyToGenerate,
    String? errorMessage,
    AiWritingFailureCode? errorCode,
    bool clearError = false,
  }) {
    return AiInterviewState(
      language: language ?? this.language,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isGenerating: isGenerating ?? this.isGenerating,
      progress: progress ?? this.progress,
      readyToGenerate: readyToGenerate ?? this.readyToGenerate,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
    );
  }
}

class AiInterviewController extends StateNotifier<AiInterviewState> {
  AiInterviewController(this._repository, {String language = 'vi'})
    : super(AiInterviewState.initial(language));

  final AiAssistantRepository _repository;

  Future<void> send(String text) async {
    final content = text.trim();
    if (content.isEmpty || state.isBusy) return;
    final clipped = content.length > _maxUserMessageLength
        ? content.substring(0, _maxUserMessageLength)
        : content;
    final history = [
      ...state.messages,
      AiChatMessage(role: AiChatRole.user, content: clipped),
    ];
    state = state.copyWith(
      messages: history,
      isSending: true,
      clearError: true,
    );
    try {
      final reply = await _repository.interview(
        messages: history,
        language: state.language,
      );
      if (!mounted) return;
      state = state.copyWith(
        isSending: false,
        messages: [
          ...history,
          AiChatMessage(role: AiChatRole.assistant, content: reply.reply),
        ],
        progress: reply.progress > state.progress
            ? reply.progress
            : state.progress,
        readyToGenerate: state.readyToGenerate || reply.readyToGenerate,
      );
    } on AiWritingFailure catch (failure) {
      if (!mounted) return;
      state = state.copyWith(
        isSending: false,
        errorMessage: failure.message,
        errorCode: failure.code,
      );
    }
  }

  /// Turns the conversation into a CV draft. Returns null on failure (the
  /// error is exposed in [state]).
  Future<ResumeImportDraft?> generate() async {
    if (!state.canGenerate) return null;
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      final draft = await _repository.generateCv(
        messages: state.messages,
        language: state.language,
      );
      if (mounted) state = state.copyWith(isGenerating: false);
      return draft;
    } on AiWritingFailure catch (failure) {
      if (mounted) {
        state = state.copyWith(
          isGenerating: false,
          errorMessage: failure.message,
          errorCode: failure.code,
        );
      }
      return null;
    }
  }

  void switchLanguage(String language) {
    if (state.isBusy || language == state.language) return;
    if (state.userTurns == 0) {
      state = AiInterviewState.initial(language);
    } else {
      state = state.copyWith(language: language);
    }
  }

  void restart() {
    if (state.isBusy) return;
    state = AiInterviewState.initial(state.language);
  }

  void dismissError() => state = state.copyWith(clearError: true);
}

final aiInterviewControllerProvider =
    StateNotifierProvider.autoDispose<AiInterviewController, AiInterviewState>(
      (ref) => AiInterviewController(ref.watch(aiAssistantRepositoryProvider)),
    );
