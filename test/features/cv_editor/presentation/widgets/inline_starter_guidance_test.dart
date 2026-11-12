import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/education_tab.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/experience_tab.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/personal_info_tab.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/projects_tab.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/skills_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PersonalInfoTab tapping starter chip fills summary', (tester) async {
    final titleCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    var changedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PersonalInfoTab(
            titleController: titleCtrl,
            fullNameController: nameCtrl,
            roleController: roleCtrl,
            emailController: emailCtrl,
            phoneController: phoneCtrl,
            locationController: locCtrl,
            summaryController: summaryCtrl,
            onFieldChanged: (_) => changedCount++,
            onAiOptimize: () {},
            isAiLoading: false,
            avatarPath: null,
            onPickAvatar: () async {},
            onRemoveAvatar: () {},
            supportsProfilePhoto: true,
            avatarPosition: 'left',
            onAvatarPositionChanged: (_) {},
            language: 'vi',
          ),
        ),
      ),
    );

    expect(find.text('Câu mẫu gợi ý:'), findsOneWidget);
    final chipFinder = find.text('Mobile / Flutter Dev');
    expect(chipFinder, findsOneWidget);
    await tester.ensureVisible(chipFinder);
    await tester.pumpAndSettle();

    await tester.tap(chipFinder);
    await tester.pump();

    expect(summaryCtrl.text, contains('Kỹ sư phần mềm Flutter'));
    expect(changedCount, greaterThanOrEqualTo(1));
  });

  testWidgets('ExperienceTab empty state offers quick starter button', (tester) async {
    var starterTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExperienceTab(
            experiences: const [],
            onAddExperience: () {},
            onUseStarterExperience: () => starterTriggered = true,
            language: 'vi',
          ),
        ),
      ),
    );

    final starterBtn = find.byKey(const Key('use-starter-experience-btn'));
    expect(starterBtn, findsOneWidget);

    await tester.tap(starterBtn);
    await tester.pump();
    expect(starterTriggered, isTrue);
  });

  testWidgets('EducationTab empty state offers quick starter button', (tester) async {
    var starterTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EducationTab(
            educations: const [],
            onAddEducation: () {},
            onUseStarterEducation: () => starterTriggered = true,
            language: 'vi',
          ),
        ),
      ),
    );

    final starterBtn = find.byKey(const Key('use-starter-education-btn'));
    expect(starterBtn, findsOneWidget);

    await tester.tap(starterBtn);
    await tester.pump();
    expect(starterTriggered, isTrue);
  });

  testWidgets('ProjectsTab empty state offers quick starter button', (tester) async {
    var starterTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectsTab(
            projects: const [],
            onAdd: () {},
            onEdit: (_) {},
            onDelete: (_) {},
            onUseStarterProjects: () => starterTriggered = true,
            language: 'vi',
          ),
        ),
      ),
    );

    final starterBtn = find.byKey(const Key('use-starter-projects-btn'));
    expect(starterBtn, findsOneWidget);

    await tester.tap(starterBtn);
    await tester.pump();
    expect(starterTriggered, isTrue);
  });

  testWidgets('SkillsTab empty state offers quick starter button', (tester) async {
    var starterTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkillsTab(
            skills: const [],
            onAddSkill: () {},
            onUseStarterSkills: () => starterTriggered = true,
            language: 'vi',
          ),
        ),
      ),
    );

    final starterBtn = find.byKey(const Key('use-starter-skills-btn'));
    expect(starterBtn, findsOneWidget);

    await tester.tap(starterBtn);
    await tester.pump();
    expect(starterTriggered, isTrue);
  });
}
