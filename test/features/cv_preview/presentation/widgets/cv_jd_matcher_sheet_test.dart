import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/cv_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/skill_model.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_jd_matcher_sheet.dart';

void main() {
  testWidgets('CvJdMatcherSheet renders and adds a missing skill', (tester) async {
    SkillModel? addedSkill;

    final cv = CvModel.empty(id: 'test-cv').copyWith(
      skills: const [
        SkillModel(id: 's1', name: 'Flutter', category: SkillCategory.hard),
        SkillModel(id: 's2', name: 'Dart', category: SkillCategory.hard),
      ],
      summary: 'Mobile Flutter developer.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CvJdMatcherSheet(
            cv: cv,
            isEnglish: false,
            onAddMissingSkill: (s) => addedSkill = s,
          ),
        ),
      ),
    );

    expect(find.text('So khớp với tin tuyển dụng'), findsOneWidget);
    expect(find.byKey(const Key('jd-preset-flutter_mobile')), findsOneWidget);

    // Missing keyword chip e.g. Firebase or Clean Architecture
    final addMissingChip = find.byKey(const Key('add-missing-Firebase'));
    expect(addMissingChip, findsOneWidget);

    await tester.tap(addMissingChip);
    await tester.pumpAndSettle();

    expect(addedSkill, isNotNull);
    expect(addedSkill!.name, 'Firebase');
  });
}

