import 'package:flutter/material.dart';

import '../../domain/models/summary_polish_request.dart';
import '../widgets/summary_polish_preview_sheet.dart';
import 'summary_polish_controller.dart';
import '../../../../core/i18n/app_language.dart';

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
            state.errorMessage ??
            tr(
              'Không thể tối ưu lúc này. Hãy thử lại.',
              'Could not improve it right now. Please try again.',
            );
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
        return SummaryPolishFlowResult.failed(
          messageVi: tr(
            'Chưa lưu được. Nội dung cũ vẫn giữ nguyên.',
            'Could not save. Your previous content is unchanged.',
          ),
          messageEn: 'Could not save. Your original text is kept.',
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
      return SummaryPolishFlowResult.failed(
        messageVi: tr(
          'Cần đăng nhập để dùng chức năng này.',
          'Please sign in to use this feature.',
        ),
        messageEn: 'Sign in to use this feature.',
      );
    }
    if (targetRole.isEmpty) {
      return SummaryPolishFlowResult.failed(
        messageVi: tr(
          'Hãy nhập vị trí ứng tuyển trước khi tối ưu.',
          'Enter the role you are applying for first.',
        ),
        messageEn: 'Enter a target role before optimizing.',
      );
    }
    if (original.length < 40) {
      return SummaryPolishFlowResult.failed(
        messageVi: tr(
          'Hãy viết ít nhất 40 ký tự trước.',
          'Write at least 40 characters first.',
        ),
        messageEn: 'The summary needs at least 40 characters.',
      );
    }
    return null;
  }
}
