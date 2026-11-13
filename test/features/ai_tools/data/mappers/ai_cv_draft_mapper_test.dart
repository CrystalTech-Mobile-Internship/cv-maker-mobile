import 'package:cv_maker_mobile/features/ai_tools/data/mappers/ai_cv_draft_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps AI CV JSON into a reviewable import draft', () {
    final draft = AiCvDraftMapper.fromJson(
      {
        'fullName': 'Nguyễn Tuấn Anh',
        'targetRole': 'Flutter Developer',
        'skills': ['Flutter', 'Dart', 'Flutter', ''],
        'experiences': [
          {
            'jobTitle': 'Thực tập sinh Mobile',
            'company': 'CrystalTech',
            'startDate': '2026-06',
            'isCurrent': true,
            'bulletPoints': ['Xây dựng app CV'],
          },
        ],
        'educations': [
          {'institution': 'ĐH Công nghệ', 'degree': 'Cử nhân'},
        ],
        'certifications': [
          {'name': 'TOEIC', 'score': 750, 'issueDate': '2025-03'},
        ],
      },
      sourceName: 'cv.pdf',
      rawText: 'raw',
      now: DateTime.utc(2026, 11, 12),
    );

    expect(draft.fullName, 'Nguyễn Tuấn Anh');
    expect(draft.skills, ['Flutter', 'Dart']);
    expect(draft.experiences.single.startDate, DateTime.utc(2026, 6));
    expect(draft.experiences.single.isCurrent, isTrue);
    expect(draft.educations.single.startDate, DateTime.utc(2026));
    expect(draft.certifications.single.score, '750');
    expect(draft.warnings, hasLength(2));
  });

  test('converts a draft into a savable CV', () {
    final draft = AiCvDraftMapper.fromJson(
      {
        'fullName': 'A',
        'skills': ['SQL'],
      },
      sourceName: 'AI',
      rawText: '',
    );
    final cv = draft.toCv(
      id: 'ai-1',
      title: 'CV AI',
      templateId: 'harvard_ats',
      primaryColor: '#1E293B',
      language: 'vi',
      now: DateTime.utc(2026),
    );
    expect(cv.skills.single.name, 'SQL');
    expect(cv.isSynced, isFalse);
  });
}
