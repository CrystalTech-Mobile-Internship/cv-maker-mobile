import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_quality_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flags missing essentials as important issues', () {
    final report = CvQualityChecker.check(CvModel.empty(id: 'cv'));

    final messages = report.issues.map((i) => i.message).join('\n');
    expect(messages, contains('Thiếu họ tên'));
    expect(messages, contains('Thiếu email'));
    expect(messages, contains('Chưa có phần tóm tắt'));
    expect(report.importantCount, greaterThanOrEqualTo(4));
    expect(report.issues.first.severity, CvIssueSeverity.important);
  });

  test('detects style problems in bullets and skills', () {
    final cv = CvModel.empty(id: 'cv').copyWith(
      personalInfo: const PersonalInfoModel(
        fullName: 'A',
        email: 'not-an-email',
      ),
      summary: 'Tôi là lập trình viên.',
      experiences: [
        ExperienceModel(
          id: 'e1',
          jobTitle: 'Dev',
          company: 'X',
          startDate: DateTime.utc(2024),
          bulletPoints: const [
            'Phát triển tính năng đăng nhập cho ứng dụng di động',
            'Phát triển màn hình thanh toán tăng [x%] chuyển đổi',
            'phát triển module thông báo đẩy cho người dùng',
          ],
        ),
      ],
      skills: const [
        SkillModel(id: '1', name: 'Dart', category: SkillCategory.hard),
        SkillModel(id: '2', name: 'dart', category: SkillCategory.hard),
      ],
    );

    final messages = CvQualityChecker.check(
      cv,
    ).issues.map((i) => i.message).join('\n');

    expect(messages, contains('Email có vẻ chưa đúng'));
    expect(messages, contains('xưng'));
    expect(messages, contains('[điền]'));
    expect(messages, contains('viết hoa'));
    expect(messages, contains('Kỹ năng bị trùng'));
    expect(messages, contains('đa dạng động từ'));
  });

  test('a well written CV scores high', () {
    final cv = CvModel.empty(id: 'cv').copyWith(
      personalInfo: const PersonalInfoModel(
        fullName: 'Nguyễn Văn A',
        email: 'a@example.com',
        phone: '0901234567',
      ),
      summary:
          'Lập trình viên Flutter với 2 năm kinh nghiệm xây dựng ứng dụng offline-first, '
          'thành thạo Riverpod, SQLite và Supabase, tập trung vào hiệu năng và trải nghiệm.',
      experiences: [
        ExperienceModel(
          id: 'e1',
          jobTitle: 'Flutter Developer',
          company: 'X',
          startDate: DateTime.utc(2024),
          bulletPoints: const [
            'Phát triển ứng dụng CV phục vụ 5.000 người dùng mỗi tháng',
            'Tối ưu thời gian khởi động giảm 40% nhờ lazy loading',
          ],
        ),
      ],
      skills: const [
        SkillModel(id: '1', name: 'Flutter', category: SkillCategory.hard),
      ],
    );

    final report = CvQualityChecker.check(cv);
    expect(report.importantCount, 0);
    expect(report.score, greaterThanOrEqualTo(90));
  });
}
