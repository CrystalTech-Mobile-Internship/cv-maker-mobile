import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_preview/domain/services/cv_sample_content_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fills only missing preview sections and preserves user data', () {
    final source = CvModel.empty(id: 'partial').copyWith(
      personalInfo: const PersonalInfoModel(fullName: 'Trần Văn Hòa'),
      summary: 'Nội dung thật của người dùng',
      projects: [
        ProjectModel(id: 'partial-project', name: 'Smart CV', role: ''),
      ],
    );

    final preview = CvSampleContentService.fillMissing(source);

    expect(preview.personalInfo.fullName, 'Trần Văn Hòa');
    expect(preview.summary, 'Nội dung thật của người dùng');
    expect(preview.personalInfo.email, 'email@example.com');
    expect(preview.educations, isNotEmpty);
    expect(preview.experiences, isNotEmpty);
    expect(preview.projects, isNotEmpty);
    expect(preview.projects.single.name, 'Smart CV');
    expect(preview.projects.single.role, 'Vai trò của bạn');
    expect(preview.projects.single.description, isNotEmpty);
    expect(preview.certifications, isNotEmpty);
    expect(source.projects.single.role, isEmpty);
    expect(source.personalInfo.email, isEmpty);
  });

  test('detects a complete CV without requiring sample sections', () {
    final complete = CvSampleContentService.fillMissing(
      CvModel.empty(id: 'complete'),
    );

    expect(CvSampleContentService.hasMissingSections(complete), isFalse);
  });
}
