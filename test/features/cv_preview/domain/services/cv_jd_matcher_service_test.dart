import 'package:flutter_test/flutter_test.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/cv_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/skill_model.dart';
import 'package:cv_maker_mobile/features/cv_preview/domain/services/cv_jd_matcher_service.dart';

void main() {
  group('CvJdMatcherService', () {
    test('evaluate calculates match rate and identifies missing keywords', () {
      final cv = CvModel.empty(id: 'test-cv').copyWith(
        title: 'Flutter Developer CV',
        skills: const [
          SkillModel(id: 's1', name: 'Flutter & Dart', category: SkillCategory.hard),
          SkillModel(id: 's2', name: 'SQLite', category: SkillCategory.hard),
        ],
        summary: 'Experienced mobile developer proficient in Flutter, RESTful API, and Git.',
      );

      final report = CvJdMatcherService.evaluate(
        cv: cv,
        targetKeywords: ['Flutter', 'Dart', 'SQLite', 'Docker', 'Kubernetes'],
      );

      expect(report.matchedKeywords, contains('Flutter'));
      expect(report.matchedKeywords, contains('Dart'));
      expect(report.matchedKeywords, contains('SQLite'));
      expect(report.missingKeywords, contains('Docker'));
      expect(report.missingKeywords, contains('Kubernetes'));
      expect(report.score, equals(60));
    });

    test('evaluate handles empty keyword list safely', () {
      final cv = CvModel.empty(id: 'test-cv');
      final report = CvJdMatcherService.evaluate(cv: cv, targetKeywords: const []);
      expect(report.score, equals(0));
      expect(report.totalKeywords, equals(0));
    });
  });
}

