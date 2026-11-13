import 'package:cv_maker_mobile/features/ai_tools/domain/services/jd_keyword_extractor.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_preview/domain/services/cv_jd_matcher_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts canonical keywords from a Vietnamese JD', () {
    const jd = '''
Yêu cầu: Thành thạo Flutter/Dart, có kinh nghiệm với Riverpod hoặc BLoC.
Biết sử dụng Git, RESTful API, PostgreSQL. Ưu tiên ứng viên có TOEIC 650+
và kỹ năng làm việc nhóm.
''';
    final keywords = JdKeywordExtractor.extract(jd);

    expect(
      keywords,
      containsAll([
        'Flutter',
        'Dart',
        'Riverpod',
        'BLoC',
        'Git',
        'REST API',
        'SQL',
        'Tiếng Anh',
        'Làm việc nhóm',
      ]),
    );
  });

  test('does not match short aliases inside other words', () {
    final keywords = JdKeywordExtractor.extract(
      'We value results, javascript-free tooling and ios experience.',
    );

    expect(keywords, isNot(contains('TypeScript')));
    expect(keywords, contains('iOS'));
  });

  test('scores a CV against free-text JD', () {
    final cv = CvModel.empty(id: 'cv-1').copyWith(
      summary: 'Flutter developer using Riverpod and GitHub daily.',
      skills: const [
        SkillModel(id: 's1', name: 'Dart', category: SkillCategory.hard),
      ],
    );

    final report = CvJdMatcherService.evaluateJobDescription(
      cv: cv,
      jobDescription: 'Cần Flutter, Dart, Riverpod, Git và Docker.',
    );

    expect(report.matchedKeywords, ['Flutter', 'Dart', 'Riverpod', 'Git']);
    expect(report.missingKeywords, ['Docker']);
    expect(report.score, 80);
  });
}
