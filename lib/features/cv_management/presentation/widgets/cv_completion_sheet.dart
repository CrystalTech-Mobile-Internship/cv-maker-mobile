import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/services/cv_completion_service.dart';
import '../../../../core/widgets/app_sheet.dart';

Future<void> showCvCompletionSheet(
  BuildContext context,
  CvModel cv, {
  required VoidCallback onContinueEditing,
}) {
  final report = CvCompletionService.evaluate(cv);
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.brandIndigo.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.primarySlate,
                  child: const Icon(Icons.fact_check_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Checklist hoàn thiện CV',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${report.completedCount}/${report.items.length} mục • ${report.percentage}%',
                        style: const TextStyle(color: AppTheme.mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: report.percentage / 100,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                color: AppTheme.brandIndigo,
              ),
            ),
            const SizedBox(height: 14),
            ...report.items.map(
              (item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: item.isCompleted
                      ? const Color(0xFF15803D)
                      : AppTheme.mutedText,
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: item.isCompleted
                        ? FontWeight.w500
                        : FontWeight.w700,
                  ),
                ),
                trailing: Text(
                  item.isCompleted ? 'Đã có' : 'Còn thiếu',
                  style: TextStyle(
                    fontSize: 12,
                    color: item.isCompleted
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('continue-cv-editing'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                onContinueEditing();
              },
              icon: const Icon(Icons.edit_rounded),
              label: Text(
                report.percentage == 100
                    ? 'Xem lại nội dung'
                    : 'Tiếp tục hoàn thiện',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
