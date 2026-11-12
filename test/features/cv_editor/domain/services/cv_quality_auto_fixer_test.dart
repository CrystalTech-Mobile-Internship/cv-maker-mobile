import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_quality_auto_fixer.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_quality_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies safe formatting fixes without rewording', () {
    final cv = CvModel.empty(id: 'cv').copyWith(
      summary: '  Lập trình viên   Flutter  ',
      personalInfo: const PersonalInfoModel(
        fullName: ' Nguyễn  Văn A ',
        email: ' A@Example.com ',
      ),
      experiences: [
        ExperienceModel(
          id: 'e1',
          jobTitle: 'Dev',
          company: 'X',
          startDate: DateTime.utc(2024),
          bulletPoints: const [
            '- phát triển tính năng đăng nhập cho ứng dụng',
            '   ',
            '• Tối ưu   hiệu năng màn hình chính',
          ],
        ),
      ],
      skills: const [
        SkillModel(id: '1', name: 'Dart', category: SkillCategory.hard),
        SkillModel(id: '2', name: 'dart ', category: SkillCategory.hard),
        SkillModel(id: '3', name: 'SQL', category: SkillCategory.hard),
      ],
    );

    final result = CvQualityAutoFixer.fix(cv);

    expect(result.hasChanges, isTrue);
    expect(result.cv.summary, 'Lập trình viên Flutter');
    expect(result.cv.personalInfo.fullName, 'Nguyễn Văn A');
    expect(result.cv.personalInfo.email, 'a@example.com');
    expect(result.cv.experiences.single.bulletPoints, [
      'Phát triển tính năng đăng nhập cho ứng dụng',
      'Tối ưu hiệu năng màn hình chính',
    ]);
    expect(result.cv.skills.map((s) => s.name), ['Dart', 'SQL']);

    final after = CvQualityChecker.check(
      result.cv,
    ).issues.map((i) => i.message);
    expect(after.any((m) => m.contains('viết hoa')), isFalse);
    expect(after.any((m) => m.contains('trùng')), isFalse);
  });

  test('reports no changes for a clean CV', () {
    final cv = CvModel.empty(id: 'cv').copyWith(summary: 'Gọn gàng');
    final result = CvQualityAutoFixer.fix(cv);
    expect(result.hasChanges, isFalse);
    expect(identical(result.cv, cv), isTrue);
  });
}
