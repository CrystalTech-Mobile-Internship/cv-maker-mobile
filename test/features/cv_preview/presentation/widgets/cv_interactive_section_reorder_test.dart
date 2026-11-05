import 'package:cv_maker_mobile/app/theme.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/cv_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/personal_info_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/experience_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/project_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/skill_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/education_model.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_interactive_section_reorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CvModel _buildTestCv() {
  return CvModel(
    id: 'test-reorder-cv',
    title: 'Test CV',
    templateId: 'harvard_ats',
    primaryColor: '#1E293B',
    fontSizeScale: 1.0,
    summary: 'Experienced Flutter engineer with strong problem solving skills.',
    personalInfo: const PersonalInfoModel(fullName: 'Nguyen Tuan Anh'),
    experiences: [
      ExperienceModel(
        id: 'exp-1',
        company: 'CrystalTech Corp',
        jobTitle: 'Flutter Engineer',
        startDate: DateTime.utc(2024, 6, 1),
        isCurrent: true,
      ),
    ],
    projects: [
      ProjectModel(
        id: 'p-1',
        name: 'Smart CV Maker Mobile',
        role: 'Lead Developer',
        startDate: DateTime.utc(2024, 8, 1),
      ),
    ],
    skills: const [
      SkillModel(id: 's-1', name: 'Flutter', category: SkillCategory.hard),
      SkillModel(id: 's-2', name: 'Dart', category: SkillCategory.hard),
    ],
    educations: [
      EducationModel(
        id: 'edu-1',
        institution: 'Hanoi University of Science and Technology',
        degree: 'Bachelor',
        fieldOfStudy: 'Computer Science',
        startDate: DateTime.utc(2020, 9, 1),
      ),
    ],
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    isSynced: true,
  );
}

void main() {
  testWidgets('CvInteractiveSectionReorder displays all sections with snippets and order badges', (tester) async {
    final cv = _buildTestCv();
    List<String>? updatedOrder;
    bool resetCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CvInteractiveSectionReorder(
            cv: cv,
            language: 'vi',
            onOrderChanged: (order) => updatedOrder = order,
            onResetToDefault: () => resetCalled = true,
          ),
        ),
      ),
    );

    // Verify all 6 section cards are present
    expect(find.byKey(const ValueKey('preview-section-summary')), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-section-experience')), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-section-projects')), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-section-skills')), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-section-education')), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-section-certifications')), findsOneWidget);

    // Verify order badges
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('#3'), findsOneWidget);
    expect(find.text('#4'), findsOneWidget);
    expect(find.text('#5'), findsOneWidget);
    expect(find.text('#6'), findsOneWidget);

    // Verify content snippets
    expect(find.textContaining('Experienced Flutter engineer'), findsOneWidget);
    expect(find.textContaining('CrystalTech Corp'), findsOneWidget);
    expect(find.textContaining('Smart CV Maker Mobile'), findsOneWidget);
    expect(find.textContaining('Flutter, Dart'), findsOneWidget);

    // Test Default Reset button
    final defaultBtn = find.text('Mặc định');
    expect(defaultBtn, findsOneWidget);
    await tester.tap(defaultBtn);
    await tester.pump();
    expect(resetCalled, isTrue);

    // Test Move Down button on first item
    final moveDownBtns = find.byTooltip('Di chuyển xuống');
    expect(moveDownBtns, findsWidgets);
    await tester.tap(moveDownBtns.first);
    await tester.pump();

    expect(updatedOrder, isNotNull);
    expect(updatedOrder![1], equals('summary'));
  });

  testWidgets('CvInteractiveSectionReorder supports English localized labels and empty state snippets', (tester) async {
    final emptyCv = CvModel.empty(id: 'empty-cv');
    List<String>? updatedOrder;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CvInteractiveSectionReorder(
            cv: emptyCv,
            language: 'en',
            onOrderChanged: (order) => updatedOrder = order,
          ),
        ),
      ),
    );

    expect(find.text('Professional Summary'), findsOneWidget);
    expect(find.text('Work Experience'), findsOneWidget);
    expect(find.text('Key Projects'), findsOneWidget);
    expect(find.text('No summary added yet.'), findsOneWidget);
    expect(find.text('No work experience yet.'), findsOneWidget);
    expect(find.text('No projects added.'), findsOneWidget);
  });
}
