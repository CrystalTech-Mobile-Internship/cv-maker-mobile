import 'package:cv_maker_mobile/features/cv_editor/domain/models/cv_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/personal_info_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_completion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports completed and missing CV sections from local data', () {
    final now = DateTime.utc(2026, 10, 28);
    final cv = CvModel(
      id: 'completion-test',
      title: 'Flutter CV',
      templateId: 'harvard_ats',
      primaryColor: '#1E293B',
      fontSizeScale: 1,
      personalInfo: const PersonalInfoModel(
        fullName: 'Nguyễn Tuấn Anh',
        targetRole: 'Flutter Developer',
        email: 'tuananh@example.com',
        phone: '0901234567',
      ),
      summary: 'Lập trình viên Flutter.',
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );

    final report = CvCompletionService.evaluate(cv);

    expect(report.items, hasLength(8));
    expect(report.completedCount, 4);
    expect(report.percentage, 50);
    expect(report.missingItems.map((item) => item.id), [
      'education',
      'experience',
      'skills',
      'projects',
    ]);
  });
}
