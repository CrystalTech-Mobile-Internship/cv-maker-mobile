import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/services/cv_quality_checker.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/i18n/app_language.dart';

final _sectionLabels = {
  'personal': tr('Thông tin cá nhân', 'Personal details'),
  'summary': tr('Tóm tắt', 'Summary'),
  'experience': tr('Kinh nghiệm', 'Experience'),
  'projects': tr('Dự án', 'Projects'),
  'education': tr('Học vấn', 'Education'),
  'skills': tr('Kỹ năng', 'Skills'),
  'certifications': tr('Chứng chỉ', 'Certifications'),
};

/// Lists writing-quality issues found by [CvQualityChecker].
Future<void> showCvQualitySheet(
  BuildContext context, {
  required CvQualityReport report,
  VoidCallback? onEdit,
  List<String> autoFixChanges = const [],
  VoidCallback? onAutoFix,
}) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.indigoSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${report.score}',
                  key: const ValueKey('cv-quality-score'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppTheme.brandIndigo,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Kiểm tra chất lượng CV', 'CV quality check'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.issues.isEmpty
                          ? tr(
                              'Không phát hiện vấn đề nào. CV đã sẵn sàng.',
                              'No problems found. Your CV is ready.',
                            )
                          : tr(
                              '${report.importantCount} vấn đề quan trọng · '
                                  '${report.issues.length - report.importantCount} gợi ý',
                              '${report.importantCount} important · ${report.issues.length - report.importantCount} suggestions',
                            ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onAutoFix != null && autoFixChanges.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.indigoSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Có thể sửa nhanh', 'Quick fixes available'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final change in autoFixChanges)
                    Text(
                      '• $change',
                      style: const TextStyle(fontSize: 12.5, height: 1.4),
                    ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const ValueKey('cv-quality-autofix'),
                    onPressed: () {
                      Navigator.pop(context);
                      onAutoFix();
                    },
                    child: Text(tr('Sửa nhanh 1 chạm', 'Fix in one tap')),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          for (final issue in report.issues)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.softBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    issue.severity == CvIssueSeverity.important
                        ? Icons.error_outline
                        : Icons.info_outline,
                    size: 18,
                    color: issue.severity == CvIssueSeverity.important
                        ? AppTheme.warningAmber
                        : AppTheme.mutedText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sectionLabels[issue.section] ?? issue.section,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          issue.message,
                          style: const TextStyle(fontSize: 13, height: 1.35),
                        ),
                        if (issue.detail != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '“${issue.detail}”',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedText,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (onEdit != null && report.issues.isNotEmpty) ...[
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onEdit();
              },
              child: Text(tr('Mở trình chỉnh sửa để sửa', 'Fix in the editor')),
            ),
          ],
        ],
      ),
    ),
  );
}
