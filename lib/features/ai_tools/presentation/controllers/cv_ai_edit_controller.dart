import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cv_editor/domain/models/cv_model.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../../domain/services/cv_section_edit_mapper.dart';
import 'ai_assistant_providers.dart';

/// One turn in the "edit this section" chat on the preview page.
class CvAiEditMessage {
  const CvAiEditMessage({
    required this.fromUser,
    required this.text,
    this.section,
    this.proposal,
    this.status = CvAiProposalStatus.none,
  });

  final bool fromUser;
  final String text;
  final String? section;

  /// The rewritten section waiting for the user's decision.
  final AiSectionEdit? proposal;
  final CvAiProposalStatus status;

  CvAiEditMessage withStatus(CvAiProposalStatus status) => CvAiEditMessage(
    fromUser: fromUser,
    text: text,
    section: section,
    proposal: proposal,
    status: status,
  );
}

enum CvAiProposalStatus { none, pending, applied, dismissed }

class CvAiEditState {
  const CvAiEditState({
    this.messages = const [],
    this.isBusy = false,
    this.errorMessage,
    this.errorCode,
  });

  final List<CvAiEditMessage> messages;
  final bool isBusy;
  final String? errorMessage;
  final AiWritingFailureCode? errorCode;

  CvAiEditState copyWith({
    List<CvAiEditMessage>? messages,
    bool? isBusy,
    String? errorMessage,
    AiWritingFailureCode? errorCode,
    bool clearError = false,
  }) => CvAiEditState(
    messages: messages ?? this.messages,
    isBusy: isBusy ?? this.isBusy,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
  );
}

class CvAiEditController extends StateNotifier<CvAiEditState> {
  CvAiEditController(this._repository) : super(const CvAiEditState());

  final AiAssistantRepository _repository;

  /// Asks the AI to rewrite [section] of [cv]. Returns false when the
  /// section has nothing to edit yet.
  Future<bool> request({
    required CvModel cv,
    required String section,
    required String instruction,
  }) async {
    final text = instruction.trim();
    if (text.isEmpty || state.isBusy) return true;
    final blocks = CvSectionEditMapper.blocksFor(cv, section);
    if (blocks.isEmpty) return false;
    state = state.copyWith(
      isBusy: true,
      clearError: true,
      messages: [
        ...state.messages,
        CvAiEditMessage(fromUser: true, text: text, section: section),
      ],
    );
    try {
      final edit = await _repository.editSection(
        section: section,
        instruction: text.length > 500 ? text.substring(0, 500) : text,
        blocks: blocks,
        language: cv.language,
      );
      if (!mounted) return true;
      state = state.copyWith(
        isBusy: false,
        messages: [
          ...state.messages,
          CvAiEditMessage(
            fromUser: false,
            text: edit.reply,
            section: section,
            proposal: edit,
            status: CvAiProposalStatus.pending,
          ),
        ],
      );
    } on AiWritingFailure catch (failure) {
      if (!mounted) return true;
      state = state.copyWith(
        isBusy: false,
        errorMessage: failure.message,
        errorCode: failure.code,
      );
    }
    return true;
  }

  void markProposal(int index, CvAiProposalStatus status) {
    if (index < 0 || index >= state.messages.length) return;
    final messages = [...state.messages];
    messages[index] = messages[index].withStatus(status);
    state = state.copyWith(messages: messages);
  }

  void dismissError() => state = state.copyWith(clearError: true);
}

final cvAiEditControllerProvider =
    StateNotifierProvider.autoDispose<CvAiEditController, CvAiEditState>(
      (ref) => CvAiEditController(ref.watch(aiAssistantRepositoryProvider)),
    );
