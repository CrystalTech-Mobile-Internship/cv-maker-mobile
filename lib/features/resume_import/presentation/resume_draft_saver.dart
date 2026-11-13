import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_providers.dart';
import '../../cv_editor/data/repositories/cv_repository_provider.dart';
import '../../cv_editor/domain/models/cv_model.dart';
import '../../cv_editor/domain/models/cv_template.dart';
import '../domain/models/resume_import_draft.dart';
import 'widgets/resume_import_review_dialog.dart';
import '../../../core/utils/cv_id.dart';

/// Shows the review dialog for [draft] (from a file import or the AI
/// assistant) and saves the confirmed CV locally. Returns the saved CV, or
/// null when the user cancels.
Future<CvModel?> reviewAndSaveResumeDraft(
  BuildContext context,
  WidgetRef ref,
  ResumeImportDraft draft, {
  String idPrefix = 'import',
}) async {
  final review = await showResumeImportReviewDialog(context, draft);
  if (review == null || !context.mounted) return null;

  final now = DateTime.now().toUtc();
  final template = CvTemplateCatalog.byId(review.templateId);
  final cv = draft.toCv(
    id: newCvId(),
    userId: ref.read(currentAuthUserProvider)?.id,
    title: review.title,
    templateId: review.templateId,
    primaryColor: template.accentHex,
    language: review.language,
    now: now,
    correctedFullName: review.fullName,
    correctedTargetRole: review.targetRole,
    correctedEmail: review.email,
    correctedPhone: review.phone,
    correctedAddress: review.address,
    correctedSummary: review.summary,
  );
  return ref.read(cvRepositoryProvider).save(cv);
}
