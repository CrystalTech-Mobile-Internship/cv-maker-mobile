import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/models.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/i18n/app_language.dart';

/// Builds the tailored copy of [cv]. The original CV is never modified.
CvModel applyTailoring(
  CvModel cv,
  AiTailorResult result, {
  required String newId,
  required String title,
  required Set<String> confirmedSkills,
  required DateTime now,
}) {
  final byName = {for (final s in cv.skills) s.name: s};
  final ordered = <SkillModel>[
    for (final name in result.skillsOrder)
      if (byName.containsKey(name)) byName.remove(name)!,
    ...byName.values,
    for (var i = 0; i < result.missingSkills.length; i++)
      if (confirmedSkills.contains(result.missingSkills[i]))
        SkillModel(
          id: '$newId-skill-$i',
          name: result.missingSkills[i],
          category: SkillCategory.hard,
          proficiency: 60,
        ),
  ];
  return cv.copyWith(
    id: newId,
    title: title,
    summary: result.summary.isEmpty ? cv.summary : result.summary,
    skills: ordered,
    experiences: [
      for (final e in cv.experiences)
        result.experienceBullets[e.id] == null
            ? e
            : e.copyWith(bulletPoints: result.experienceBullets[e.id]),
    ],
    isSynced: false,
    createdAt: now,
    updatedAt: now,
  );
}

/// Shows the AI proposal; returns the confirmed missing skills, or null if
/// the user cancels.
Future<Set<String>?> showAiTailorReviewSheet(
  BuildContext context, {
  required CvModel cv,
  required AiTailorResult result,
}) {
  return showAppSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _TailorSheet(cv: cv, result: result),
  );
}

class _TailorSheet extends StatefulWidget {
  const _TailorSheet({required this.cv, required this.result});

  final CvModel cv;
  final AiTailorResult result;

  @override
  State<_TailorSheet> createState() => _TailorSheetState();
}

class _TailorSheetState extends State<_TailorSheet> {
  final _confirmed = <String>{};

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    TextStyle label() => const TextStyle(
      fontWeight: FontWeight.w800,
      color: AppTheme.primaryNavy,
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            tr(
              'Đề xuất chỉnh CV theo tin tuyển dụng',
              'Suggested changes for this job',
            ),
            style: label().copyWith(fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Ứng dụng sẽ tạo một bản CV mới; CV gốc giữ nguyên.',
              'A new copy will be created; your original CV stays the same.',
            ),
            style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 16),
          if (result.summary.isNotEmpty) ...[
            Text(tr('Tóm tắt mới', 'New summary'), style: label()),
            const SizedBox(height: 6),
            Text(result.summary, style: const TextStyle(height: 1.45)),
            const SizedBox(height: 16),
          ],
          if (result.skillsOrder.isNotEmpty) ...[
            Text(
              tr('Thứ tự kỹ năng ưu tiên', 'Suggested skill order'),
              style: label(),
            ),
            const SizedBox(height: 6),
            Text(
              result.skillsOrder.join(' · '),
              style: const TextStyle(color: AppTheme.primarySlate),
            ),
            const SizedBox(height: 16),
          ],
          if (result.missingSkills.isNotEmpty) ...[
            Text(
              tr(
                'Kỹ năng tin tuyển dụng yêu cầu mà CV chưa có',
                'Skills the job asks for that your CV lacks',
              ),
              style: label(),
            ),
            const SizedBox(height: 2),
            Text(
              tr(
                'Chỉ chọn những kỹ năng bạn thật sự có.',
                'Only pick skills you really have.',
              ),
              style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
            ),
            for (final skill in result.missingSkills)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: _confirmed.contains(skill),
                title: Text(skill),
                onChanged: (value) => setState(() {
                  value == true
                      ? _confirmed.add(skill)
                      : _confirmed.remove(skill);
                }),
              ),
            const SizedBox(height: 8),
          ],
          for (final e in widget.cv.experiences)
            if (result.experienceBullets[e.id] != null) ...[
              Text('${e.jobTitle} — ${e.company}', style: label()),
              const SizedBox(height: 6),
              for (final line in result.experienceBullets[e.id]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $line', style: const TextStyle(height: 1.4)),
                ),
              const SizedBox(height: 12),
            ],
          for (final note in result.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                note,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.mutedText,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('Hủy', 'Cancel')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('tailor-create-copy'),
                  onPressed: () => Navigator.pop(context, {..._confirmed}),
                  child: Text(tr('Tạo bản CV tối ưu', 'Create tailored copy')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
