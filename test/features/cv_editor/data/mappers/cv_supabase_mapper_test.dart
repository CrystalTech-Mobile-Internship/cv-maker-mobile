import 'package:cv_maker_mobile/features/cv_editor/data/mappers/cv_supabase_mapper.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a domain CV to and from Supabase storage shapes', () {
    final now = DateTime.utc(2026, 10, 7);
    final cv = CvModel(
      id: 'local-cv-1',
      userId: 'user-1',
      title: 'Flutter CV',
      templateId: 'harvard_ats',
      primaryColor: '#1E293B',
      fontSizeScale: 1,
      personalInfo: const PersonalInfoModel(
        fullName: 'Nguyễn Văn A',
        targetRole: 'Flutter Developer',
      ),
      summary: 'Mobile developer',
      educations: [
        EducationModel(
          id: 'education-1',
          institution: 'Đại học A',
          degree: 'Cử nhân',
          fieldOfStudy: 'Kỹ thuật phần mềm',
          startDate: DateTime.utc(2022),
        ),
      ],
      experiences: const [],
      skills: const [],
      projects: const [],
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );

    final row = CvSupabaseMapper.toCvRow(cv, userId: 'user-1');
    final personalInfo = row['personal_info'] as Map<String, dynamic>;

    expect(row, isNot(contains('id')));
    expect(row['user_id'], 'user-1');
    expect(personalInfo['full_name'], 'Nguyễn Văn A');
    expect(personalInfo['target_role'], 'Flutter Developer');

    final restored = CvSupabaseMapper.fromCvRow({
      ...row,
      'id': '00000000-0000-4000-8000-000000000001',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'cv_sections': [
        {
          'section_type': 'experience',
          'cv_items': [
            {
              'id': 'item-1',
              'payload': {
                'jobTitle': 'Flutter Developer',
                'company': 'Company A',
                'startDate': now.toIso8601String(),
                'bulletPoints': ['Built mobile features'],
              },
            },
          ],
        },
      ],
    });

    expect(restored.id, '00000000-0000-4000-8000-000000000001');
    expect(restored.isSynced, isTrue);
    expect(restored.personalInfo.targetRole, 'Flutter Developer');
    expect(restored.experiences.single.jobTitle, 'Flutter Developer');
    expect(restored.experiences.single.bulletPoints, ['Built mobile features']);
  });

  test('preserves language, section order and hidden sections', () {
    final now = DateTime.utc(2026, 11, 12);
    final cv = CvModel.empty(id: 'cv-layout', now: now).copyWith(
      language: 'en',
      sectionOrder: const [
        'skills',
        'summary',
        'experience',
        'projects',
        'education',
        'certifications',
      ],
      hiddenSections: const ['certifications'],
    );

    final row = CvSupabaseMapper.toCvRow(cv, userId: 'user-1');
    final restored = CvSupabaseMapper.fromCvRow({
      ...row,
      'id': '00000000-0000-4000-8000-000000000002',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    expect(restored.language, 'en');
    expect(restored.sectionOrder.first, 'skills');
    expect(restored.hiddenSections, ['certifications']);
  });

  test('falls back to defaults for rows without layout settings', () {
    final restored = CvSupabaseMapper.fromCvRow({
      'id': '00000000-0000-4000-8000-000000000003',
      'updated_at': '2026-11-12T00:00:00Z',
      'layout_settings': {
        'section_order': ['unknown_section'],
        'hidden_sections': ['bogus'],
      },
    });

    expect(restored.language, 'vi');
    expect(restored.sectionOrder, CvModel.defaultSectionOrder);
    expect(restored.hiddenSections, isEmpty);
  });
}
