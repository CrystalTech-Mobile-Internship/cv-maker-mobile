import 'package:cv_maker_mobile/features/ai_tools/domain/models/ai_assistant_models.dart';
import 'package:cv_maker_mobile/features/ai_tools/domain/services/cv_section_edit_mapper.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cv = CvModel.empty(id: 'cv-1').copyWith(
    summary: 'Old summary',
    experiences: [
      ExperienceModel(
        id: 'e1',
        jobTitle: 'Intern',
        company: 'ACME',
        startDate: DateTime.utc(2024),
        bulletPoints: const ['• Built an app', ''],
      ),
      ExperienceModel(
        id: 'e2',
        jobTitle: 'Dev',
        company: 'Beta',
        startDate: DateTime.utc(2025),
        bulletPoints: const ['Wrote APIs'],
      ),
    ],
    skills: const [
      SkillModel(id: 's1', name: 'Dart', category: SkillCategory.hard),
      SkillModel(id: 's2', name: 'Git', category: SkillCategory.hard),
    ],
  );

  test('sends clean experience bullets with their ids', () {
    final blocks = CvSectionEditMapper.blocksFor(cv, 'experience');
    expect(blocks.map((b) => b.id), ['e1', 'e2']);
    expect(blocks.first.lines, ['Built an app']);
    expect(blocks.first.title, 'Intern - ACME');
  });

  test('applies only the experiences that came back', () {
    final updated = CvSectionEditMapper.apply(
      cv,
      'experience',
      const AiSectionEdit(
        blocks: {
          'e2': ['- Designed REST APIs'],
        },
      ),
    );
    expect(updated.experiences[0].bulletPoints, cv.experiences[0].bulletPoints);
    expect(updated.experiences[1].bulletPoints, ['Designed REST APIs']);
  });

  test('keeps existing skill ids and drops duplicates', () {
    final updated = CvSectionEditMapper.apply(
      cv,
      'skills',
      const AiSectionEdit(
        blocks: {
          'skills': ['git', 'Dart', 'GIT', 'Flutter'],
        },
      ),
    );
    expect(updated.skills.map((s) => s.name), ['Git', 'Dart', 'Flutter']);
    expect(updated.skills.first.id, 's2');
  });

  test('summary edit replaces the summary text', () {
    final updated = CvSectionEditMapper.apply(
      cv,
      'summary',
      const AiSectionEdit(
        blocks: {
          'summary': ['New summary.'],
        },
      ),
    );
    expect(updated.summary, 'New summary.');
    expect(
      CvSectionEditMapper.blocksFor(CvModel.empty(id: 'x'), 'summary'),
      isEmpty,
    );
  });
}
