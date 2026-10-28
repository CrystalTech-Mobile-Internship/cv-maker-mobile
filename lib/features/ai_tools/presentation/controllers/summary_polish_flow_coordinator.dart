import 'package:flutter/material.dart';

import '../../domain/models/summary_polish_request.dart';
import '../widgets/summary_polish_preview_sheet.dart';
import 'summary_polish_controller.dart';

enum SummaryPolishFlowStatus { applied, cancelled, failed }

class SummaryPolishFlowResult {
  const SummaryPolishFlowResult._({
    required this.status,
    this.suggestion,
    this.messageVi,
    this.messageEn,
  });

  const SummaryPolishFlowResult.applied(String suggestion)
    : this._(status: SummaryPolishFlowStatus.applied, suggestion: suggestion);

  const SummaryPolishFlowResult.cancelled()
    : this._(status: SummaryPolishFlowStatus.cancelled);

  const SummaryPolishFlowResult.failed({
    required String messageVi,
    required String messageEn,
  }) : this._(
         status: SummaryPolishFlowStatus.failed,
         messageVi: messageVi,
         messageEn: messageEn,
       );

  final SummaryPolishFlowStatus status;
  final String? suggestion;
  final String? messageVi;
  final String? messageEn;
}

/// Coordinates validation, retries, preview and local-first persistence.
class SummaryPolishFlowCoordinator {
  const SummaryPolishFlowCoordinator();

  Future<SummaryPolishFlowResult> run({
    required BuildContext context,
    required SummaryPolishController controller,
    required bool isAuthenticated,
    required String original,
    required String targetRole,
    required String language,
    required List<String> skills,
    required Future<void> Function(String suggestion) persistSuggestion,
    VoidCallback? onSaving,
  }) async {
    final validation = _validate(
      isAuthenticated: isAuthenticated,
      original: original,
      targetRole: targetRole,
    );
    if (validation != null) return validation;

    final request = SummaryPolishRequest(
      currentSummary: original,
      targetRole: targetRole,
      language: language,
      skills: skills,
    );

    while (context.mounted) {
      final state = await controller.polish(request);
      if (!context.mounted) {
        controller.reset();
        return const SummaryPolishFlowResult.cancelled();
      }

      final suggestion = state.suggestedSummary;
      if (state.status != SummaryPolishStatus.success || suggestion == null) {
        controller.reset();
        final message =
            state.errorMessage ?? 'Không thể tối ưu lúc này. Hãy thử lại.';
        return SummaryPolishFlowResult.failed(
          messageVi: message,
          messageEn: message,
        );
      }

      final action = await showSummaryPolishPreviewSheet(
        context: context,
        original: original,
        suggested: suggestion,
        provider: state.provider ?? 'AI',
        isEnglish: language == 'en',
      );
      controller.reset();
      if (!context.mounted) {
        return const SummaryPolishFlowResult.cancelled();
      }
      if (action == SummaryPolishPreviewAction.retry) continue;
      if (action == SummaryPolishPreviewAction.keepOriginal) {
        return const SummaryPolishFlowResult.cancelled();
      }

      onSaving?.call();
      try {
        await persistSuggestion(suggestion);
        return SummaryPolishFlowResult.applied(suggestion);
      } catch (_) {
        return const SummaryPolishFlowResult.failed(
          messageVi: 'Không thể lưu gợi ý AI. Nội dung gốc vẫn an toàn.',
          messageEn:
              'Could not save the AI suggestion. Original content is safe.',
        );
      }
    }

    return const SummaryPolishFlowResult.cancelled();
  }

  SummaryPolishFlowResult? _validate({
    required bool isAuthenticated,
    required String original,
    required String targetRole,
  }) {
    if (!isAuthenticated) {
      return const SummaryPolishFlowResult.failed(
        messageVi: 'Đăng nhập để sử dụng trợ lý AI an toàn.',
        messageEn: 'Sign in to use the AI writing assistant.',
      );
    }
    if (targetRole.isEmpty) {
      return const SummaryPolishFlowResult.failed(
        messageVi: 'Hãy nhập vị trí ứng tuyển trước khi tối ưu.',
        messageEn: 'Enter a target role before optimizing.',
      );
    }
    if (original.length < 40) {
      return const SummaryPolishFlowResult.failed(
        messageVi: 'Tóm tắt cần ít nhất 40 ký tự để AI có đủ ngữ cảnh.',
        messageEn: 'The summary needs at least 40 characters.',
      );
    }
    return null;
  }
}
