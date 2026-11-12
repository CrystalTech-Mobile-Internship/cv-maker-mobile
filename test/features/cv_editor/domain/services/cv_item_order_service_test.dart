import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_item_order_service.dart';
import 'package:flutter_test/flutter_test.dart';

CvModel _cv() => CvModel.empty(id: 'cv-1').copyWith(
  experiences: [
    ExperienceModel(
      id: 'old',
      jobTitle: 'Intern',
      company: 'A',
      startDate: DateTime.utc(2022, 1),
      endDate: DateTime.utc(2022, 6),
    ),
    ExperienceModel(
      id: 'current',
      jobTitle: 'Developer',
      company: 'B',
      startDate: DateTime.utc(2023, 1),
      isCurrent: true,
    ),
    ExperienceModel(
      id: 'mid',
      jobTitle: 'Junior',
      company: 'C',
      startDate: DateTime.utc(2022, 7),
      endDate: DateTime.utc(2022, 12),
    ),
  ],
  skills: const [
    SkillModel(id: 's1', name: 'Dart', category: SkillCategory.hard),
    SkillModel(id: 's2', name: 'Teamwork', category: SkillCategory.soft),
  ],
);

void main() {
  test('summarises entries of a section', () {
    final items = CvItemOrderService.itemsFor(_cv(), 'experience');
    expect(items.map((i) => i.id), ['old', 'current', 'mid']);
    expect(items[1].subtitle, contains('nay'));
  });

  test('sorts newest first with current roles on top', () {
    final items = CvItemOrderService.itemsFor(_cv(), 'experience');
    expect(CvItemOrderService.newestFirst(items), ['current', 'mid', 'old']);
  });

  test('reorders entries and never drops unknown ones', () {
    final reordered = CvItemOrderService.reorder(_cv(), 'experience', [
      'mid',
      'ghost',
      'old',
    ]);
    expect(reordered.experiences.map((e) => e.id), ['mid', 'old', 'current']);
  });

  test('reorders skills', () {
    final reordered = CvItemOrderService.reorder(_cv(), 'skills', ['s2', 's1']);
    expect(reordered.skills.first.name, 'Teamwork');
  });

  test('ignores sections without entries', () {
    final cv = _cv();
    expect(CvItemOrderService.reorder(cv, 'summary', const ['x']), same(cv));
  });
}
