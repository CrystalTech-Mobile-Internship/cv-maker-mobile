import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/skill_model.dart';
import '../../../cv_editor/domain/services/cv_bullet_cleaner.dart';
import '../models/ai_assistant_models.dart';

/// Sections that can be rewritten from the preview chat.
abstract final class CvEditableSection {
  static const summary = 'summary';
  static const experience = 'experience';
  static const projects = 'projects';
  static const skills = 'skills';

  static const all = [summary, experience, projects, skills];

  static String label(String section, {bool english = false}) =>
      switch (section) {
        summary => english ? 'Summary' : 'Tóm tắt',
        experience => english ? 'Experience' : 'Kinh nghiệm',
        projects => english ? 'Projects' : 'Dự án',
        skills => english ? 'Skills' : 'Kỹ năng',
        _ => section,
      };
}

/// Converts one CV section to plain text blocks for the AI and applies the
/// rewritten blocks back. Only ids that were sent can change.
abstract final class CvSectionEditMapper {
  static List<AiEditBlock> blocksFor(CvModel cv, String section) {
    switch (section) {
      case CvEditableSection.summary:
        final text = cv.summary.trim();
        return [
          if (text.isNotEmpty)
            AiEditBlock(id: 'summary', title: 'Summary', lines: [text]),
        ];
      case CvEditableSection.experience:
        return [
          for (final e in cv.experiences)
            if (_clean(e.bulletPoints).isNotEmpty)
              AiEditBlock(
                id: e.id,
                title: [
                  e.jobTitle,
                  e.company,
                ].where((p) => p.trim().isNotEmpty).join(' - '),
                lines: _clean(e.bulletPoints),
              ),
        ];
      case CvEditableSection.projects:
        return [
          for (final p in cv.projects)
            if (_projectLines(p.description).isNotEmpty)
              AiEditBlock(
                id: p.id,
                title: p.name,
                lines: _projectLines(p.description),
              ),
        ];
      case CvEditableSection.skills:
        return [
          if (cv.skills.isNotEmpty)
            AiEditBlock(
              id: 'skills',
              title: 'Skills',
              lines: [for (final s in cv.skills) s.name],
            ),
        ];
    }
    return const [];
  }

  static CvModel apply(CvModel cv, String section, AiSectionEdit edit) {
    final byId = edit.blocks;
    switch (section) {
      case CvEditableSection.summary:
        final lines = byId['summary'];
        if (lines == null || lines.isEmpty) return cv;
        return cv.copyWith(summary: lines.join(' ').trim());
      case CvEditableSection.experience:
        return cv.copyWith(
          experiences: [
            for (final e in cv.experiences)
              byId[e.id] == null
                  ? e
                  : e.copyWith(bulletPoints: _clean(byId[e.id]!)),
          ],
        );
      case CvEditableSection.projects:
        return cv.copyWith(
          projects: [
            for (final p in cv.projects)
              byId[p.id] == null
                  ? p
                  : p.copyWith(description: _clean(byId[p.id]!).join('\n')),
          ],
        );
      case CvEditableSection.skills:
        final names = byId['skills'];
        if (names == null || names.isEmpty) return cv;
        final existing = {for (final s in cv.skills) s.name.toLowerCase(): s};
        final seen = <String>{};
        final skills = <SkillModel>[];
        for (var i = 0; i < names.length; i++) {
          final name = names[i].trim();
          final key = name.toLowerCase();
          if (name.isEmpty || !seen.add(key)) continue;
          skills.add(
            existing[key] ??
                SkillModel(
                  id: 'skill-ai-${DateTime.now().microsecondsSinceEpoch}-$i',
                  name: name,
                  category: SkillCategory.hard,
                ),
          );
        }
        return cv.copyWith(skills: skills);
    }
    return cv;
  }

  static List<String> _projectLines(String description) =>
      _clean(description.split('\n'));

  static List<String> _clean(List<String> lines) => [
    for (final line in lines)
      if (CvBulletCleaner.line(line).trim().isNotEmpty)
        CvBulletCleaner.line(line).trim(),
  ];
}
