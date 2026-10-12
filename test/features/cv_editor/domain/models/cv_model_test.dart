import 'dart:convert';

import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CvModel', () {
    test('creates an unsynced guest CV with stable defaults', () {
      final now = DateTime.utc(2026, 10, 6, 8, 30);

      final cv = CvModel.empty(id: 'cv-1', now: now);

      expect(cv.id, 'cv-1');
      expect(cv.userId, isNull);
      expect(cv.title, 'CV chưa đặt tên');
      expect(cv.templateId, 'harvard_ats');
      expect(cv.isSynced, isFalse);
      expect(cv.createdAt, now);
      expect(cv.updatedAt, now);
      expect(cv.educations, isEmpty);
      expect(cv.experiences, isEmpty);
      expect(cv.skills, isEmpty);
      expect(cv.projects, isEmpty);
    });

    test('round-trips nested data through JSON without losing values', () {
      final cv = _buildCompleteCv();

      final decoded = CvModel.fromJson(
        jsonDecode(jsonEncode(cv.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.id, cv.id);
      expect(decoded.userId, cv.userId);
      expect(decoded.language, cv.language);
      expect(decoded.personalInfo.fullName, 'Nguyễn Văn Mẫu');
      expect(decoded.educations.single.institution, 'Đại học Mẫu');
      expect(decoded.experiences.single.bulletPoints, hasLength(2));
      expect(decoded.skills.single.category, SkillCategory.hard);
      expect(decoded.projects.single.technologies, ['Flutter', 'Supabase']);
      expect(decoded.createdAt, cv.createdAt);
      expect(decoded.updatedAt, cv.updatedAt);
    });

    test('copyWith can explicitly clear nullable ownership', () {
      final accountCv = _buildCompleteCv();

      final guestCv = accountCv.copyWith(userId: null, isSynced: false);

      expect(guestCv.userId, isNull);
      expect(guestCv.isSynced, isFalse);
      expect(guestCv.id, accountCv.id);
    });

    test('protects nested lists from external mutation', () {
      final sourceSkills = <SkillModel>[
        const SkillModel(
          id: 'skill-1',
          name: 'Flutter',
          category: SkillCategory.hard,
          proficiency: 80,
        ),
      ];
      final cv = CvModel.empty(id: 'cv-1').copyWith(skills: sourceSkills);

      sourceSkills.clear();

      expect(cv.skills, hasLength(1));
      expect(
        () => cv.skills.add(
          const SkillModel(
            id: 'skill-2',
            name: 'Giao tiếp',
            category: SkillCategory.soft,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('CV seed assets', () {
    const assetPaths = [
      'assets/mock_cvs/student_cv.json',
      'assets/mock_cvs/fresher_cv.json',
      'assets/mock_cvs/experienced_cv.json',
      'assets/mock_cvs/tuananh_fullstack_cv.json',
    ];

    for (final assetPath in assetPaths) {
      test('parses $assetPath into a complete CvModel', () async {
        final source = await rootBundle.loadString(assetPath);
        final cv = CvModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

        expect(cv.id, isNotEmpty);
        expect(cv.title, isNotEmpty);
        expect(cv.personalInfo.fullName, isNotEmpty);
        expect(cv.educations, isNotEmpty);
        expect(cv.skills, isNotEmpty);
        expect(cv.projects, isNotEmpty);
        expect(cv.isSynced, isFalse);
        expect(() => jsonEncode(cv.toJson()), returnsNormally);
      });
    }
  });

  test('rejects unsupported skill categories', () {
    expect(
      () => SkillModel.fromJson({
        'id': 'skill-1',
        'name': 'Unknown',
        'category': 'unsupported',
        'proficiency': 10,
      }),
      throwsFormatException,
    );
  });
}

CvModel _buildCompleteCv() {
  return CvModel(
    id: 'cv-complete',
    userId: 'user-1',
    title: 'CV Flutter Developer',
    templateId: 'harvard_ats',
    primaryColor: '#1E293B',
    fontSizeScale: 1,
    personalInfo: const PersonalInfoModel(
      fullName: 'Nguyễn Văn Mẫu',
      targetRole: 'Flutter Developer',
      email: 'developer@example.com',
      phone: '0900000000',
      address: 'Hà Nội, Việt Nam',
      linkedInUrl: 'https://www.linkedin.com/in/developer-example',
      githubUrl: 'https://github.com/developer-example',
    ),
    summary: 'Flutter developer tập trung vào sản phẩm offline-first.',
    educations: [
      EducationModel(
        id: 'education-1',
        institution: 'Đại học Mẫu',
        degree: 'Cử nhân',
        fieldOfStudy: 'Kỹ thuật phần mềm',
        startDate: DateTime.utc(2022, 9),
        endDate: DateTime.utc(2026, 6),
        gpa: '3.5/4.0',
        achievements: const ['Học bổng học kỳ'],
      ),
    ],
    experiences: [
      ExperienceModel(
        id: 'experience-1',
        jobTitle: 'Flutter Intern',
        company: 'Công ty Mẫu',
        startDate: DateTime.utc(2026, 1),
        endDate: DateTime.utc(2026, 4),
        bulletPoints: const [
          'Phát triển màn hình Flutter.',
          'Viết widget test.',
        ],
      ),
    ],
    skills: const [
      SkillModel(
        id: 'skill-1',
        name: 'Flutter',
        category: SkillCategory.hard,
        proficiency: 85,
      ),
    ],
    projects: [
      ProjectModel(
        id: 'project-1',
        name: 'Smart CV Maker',
        role: 'Mobile Developer',
        description: 'Ứng dụng tạo CV offline-first.',
        technologies: const ['Flutter', 'Supabase'],
        sourceUrl: 'https://github.com/example/smart-cv-maker',
        startDate: DateTime.utc(2026, 10),
      ),
    ],
    isSynced: true,
    createdAt: DateTime.utc(2026, 10, 6, 1),
    updatedAt: DateTime.utc(2026, 10, 6, 2),
  );
}
