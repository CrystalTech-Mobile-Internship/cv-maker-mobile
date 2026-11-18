import 'package:cv_maker_mobile/features/ai_tools/presentation/controllers/ai_assistant_providers.dart';
import 'package:cv_maker_mobile/features/cv_editor/data/repositories/cv_repository_provider.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/screens/cv_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../ai_tools/helpers/fake_ai_assistant_repository.dart';
import '../../../cv_management/presentation/screens/home_screen_test.dart'
    show FakeCvRepository;

void main() {
  CvModel cv() => CvModel.empty(id: 'cv-desk').copyWith(
    summary: 'Backend developer.',
    personalInfo: const PersonalInfoModel(fullName: 'Test User'),
  );

  Future<FakeCvRepository> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeCvRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cvRepositoryProvider.overrideWithValue(repo),
          aiAssistantRepositoryProvider.overrideWithValue(
            FakeAiAssistantRepository(),
          ),
        ],
        child: MaterialApp(home: CvPreviewScreen(cv: cv())),
      ),
    );
    await tester.pump();
    return repo;
  }

  testWidgets('computer layout shows sections, print view and edit chat', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byKey(const Key('preview-mode-segmented')), findsNothing);
    expect(find.byKey(const Key('preview-section-panel')), findsOneWidget);
    expect(find.byKey(const Key('preview-desktop-toolbar')), findsOneWidget);
    expect(find.text('Nhờ sửa CV'), findsOneWidget);
    expect(find.byKey(const Key('preview-download')), findsOneWidget);
  });

  testWidgets('text size buttons and Ctrl+Z undo update the CV', (
    tester,
  ) async {
    final repo = await pump(tester);
    expect(find.text('100%').first, findsOneWidget);

    await tester.tap(find.byTooltip('Lớn hơn (Ctrl + ])'));
    await tester.pump();
    expect(find.text('105%'), findsOneWidget);
    expect((await repo.getById('cv-desk'))?.fontSizeScale, 1.05);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.text('105%'), findsNothing);
    expect((await repo.getById('cv-desk'))?.fontSizeScale, 1.0);
  });

  testWidgets('Ctrl+K hides the edit chat', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.text('Nhờ sửa CV'), findsNothing);
  });

  testWidgets('picking a section shows a chip that the x removes', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('ai-edit-selected')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('ai-edit-section-summary')));
    await tester.pump();
    expect(find.byKey(const ValueKey('ai-edit-selected')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ai-edit-selected-remove')));
    await tester.pump();
    expect(find.byKey(const ValueKey('ai-edit-selected')), findsNothing);
  });
}
