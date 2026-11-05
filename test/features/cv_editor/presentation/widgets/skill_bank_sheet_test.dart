import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/skill_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/skill_bank_sheet.dart';

void main() {
  testWidgets('SkillBankSheet renders and calls onAddSkill when chip is selected', (tester) async {
    SkillModel? addedSkill;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SkillBankSheet(
            existingSkills: const [
              SkillModel(id: 's1', name: 'Flutter & Dart', category: SkillCategory.hard),
            ],
            onAddSkill: (s) => addedSkill = s,
            language: 'vi',
          ),
        ),
      ),
    );

    expect(find.text('Thư viện kỹ năng gợi ý'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Existing skill should show as selected/checked
    final existingChip = tester.widget<FilterChip>(find.byKey(const Key('skill-chip-Flutter & Dart')));
    expect(existingChip.selected, isTrue);

    // Tap an unselected chip
    final newChipFinder = find.byKey(const Key('skill-chip-Clean Architecture'));
    expect(newChipFinder, findsOneWidget);

    await tester.tap(newChipFinder);
    await tester.pumpAndSettle();

    expect(addedSkill, isNotNull);
    expect(addedSkill!.name, 'Clean Architecture');
  });
}
