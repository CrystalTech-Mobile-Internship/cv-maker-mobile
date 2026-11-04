import 'dart:convert';

import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_starter_template_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CvSectionDefinition', () {
    test('contains all standard CV sections with valid metadata', () {
      expect(CvSectionDefinition.all, hasLength(6));
      expect(CvSectionDefinition.findById('summary'), isNotNull);
      expect(CvSectionDefinition.findById('experience'), isNotNull);
      expect(CvSectionDefinition.findById('projects'), isNotNull);
      expect(CvSectionDefinition.findById('education'), isNotNull);
      expect(CvSectionDefinition.findById('skills'), isNotNull);
      expect(CvSectionDefinition.findById('certifications'), isNotNull);

      final summary = CvSectionDefinition.summary;
      expect(summary.title('vi'), 'Mục tiêu nghề nghiệp');
      expect(summary.title('en'), 'Professional Summary');
    });
  });

  group('CvModel Section Ordering', () {
    test('defaults to standard 6-section sequence', () {
      final cv = CvModel.empty(id: 'test-1');
      expect(cv.sectionOrder, CvModel.defaultSectionOrder);
      expect(cv.effectiveSectionOrder, [
        'summary',
        'experience',
        'projects',
        'education',
        'skills',
        'certifications',
      ]);
    });

    test('retains custom reordered sections in JSON roundtrip', () {
      final customOrder = [
        'projects',
        'skills',
        'experience',
        'education',
        'summary',
        'certifications',
      ];
      final cv = CvModel.empty(id: 'test-2').copyWith(sectionOrder: customOrder);

      final encoded = jsonEncode(cv.toJson());
      final decoded = CvModel.fromJson(jsonDecode(encoded) as Map<String, dynamic>);

      expect(decoded.sectionOrder, customOrder);
      expect(decoded.effectiveSectionOrder.first, 'projects');
    });

    test('effectiveSectionOrder safely appends missing sections', () {
      final incompleteOrder = ['projects', 'skills'];
      final cv = CvModel.empty(id: 'test-3').copyWith(sectionOrder: incompleteOrder);

      final effective = cv.effectiveSectionOrder;
      expect(effective.take(2).toList(), ['projects', 'skills']);
      expect(effective, containsAll(CvModel.defaultSectionOrder));
      expect(effective, hasLength(6));
    });
  });

  group('CvStarterTemplateService', () {
    test('provides bilingual starter summaries for varied roles', () {
      expect(CvStarterTemplateService.summaryOptions, isNotEmpty);
      for (final option in CvStarterTemplateService.summaryOptions) {
        expect(option.title('vi'), isNotEmpty);
        expect(option.title('en'), isNotEmpty);
        expect(option.content('vi'), isNotEmpty);
        expect(option.content('en'), isNotEmpty);
      }
    });

    test('provides structured starter items for experiences, projects, skills, education, certifications', () {
      final expVi = CvStarterTemplateService.getStarterExperiences('vi');
      final expEn = CvStarterTemplateService.getStarterExperiences('en');
      expect(expVi.single.company, isNotEmpty);
      expect(expEn.single.bulletPoints, isNotEmpty);

      final projVi = CvStarterTemplateService.getStarterProjects('vi');
      expect(projVi.single.technologies, contains('Flutter'));

      final skills = CvStarterTemplateService.getStarterSkills('vi');
      expect(skills.length, greaterThanOrEqualTo(4));

      final edu = CvStarterTemplateService.getStarterEducation('vi');
      expect(edu.single.institution, isNotEmpty);

      final certs = CvStarterTemplateService.getStarterCertifications('vi');
      expect(certs.single.name, contains('TOEIC'));
    });
  });
}
