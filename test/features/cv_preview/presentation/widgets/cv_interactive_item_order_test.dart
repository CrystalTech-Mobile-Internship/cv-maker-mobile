import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_interactive_section_reorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final withSkills = CvModel.empty(id: 'cv').copyWith(
    skills: const [
      SkillModel(id: 's1', name: 'Dart', category: SkillCategory.hard),
      SkillModel(id: 's2', name: 'SQL', category: SkillCategory.hard),
    ],
  );

  Future<String?> pump(
    WidgetTester tester, {
    required CvModel shown,
    CvModel? content,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CvInteractiveSectionReorder(
            cv: shown,
            contentCv: content,
            language: 'vi',
            onOrderChanged: (_) {},
            onReorderItems: (section) => opened = section,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('reorder-items-skills')));
    return opened;
  }

  testWidgets('offers entry ordering for real entries', (tester) async {
    expect(await pump(tester, shown: withSkills), 'skills');
    expect(find.text('2 mục · chạm để sắp xếp'), findsOneWidget);
  });

  testWidgets('ignores sample filler entries', (tester) async {
    final opened = await pump(
      tester,
      shown: withSkills,
      content: CvModel.empty(id: 'cv'),
    );
    expect(opened, isNull);
    expect(find.text('2 mục · chạm để sắp xếp'), findsNothing);
  });
}
