import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/editor_typography_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EditorTypographyToolbar inserts bold text, bullets and triggers font dialog', (tester) async {
    final controller = TextEditingController(text: 'Hello world');
    double? updatedScale;
    bool reorderOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                EditorTypographyToolbar(
                  currentScale: 1.0,
                  language: 'vi',
                  onScaleChanged: (scale) => updatedScale = scale,
                  textController: controller,
                  onOpenSectionReorder: () => reorderOpened = true,
                ),
                TextField(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify chips
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Sắp xếp mục'), findsOneWidget);

    // Tap Reorder chip
    await tester.tap(find.text('Sắp xếp mục'));
    await tester.pump();
    expect(reorderOpened, isTrue);

    // Tap bold button
    final boldButton = find.byTooltip('In đậm (**chữ**)');
    expect(boldButton, findsOneWidget);
    await tester.tap(boldButton);
    await tester.pump();

    expect(controller.text, contains('**'));

    // Tap font size chip
    await tester.tap(find.text('100%'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh cỡ chữ CV'), findsOneWidget);
    expect(find.text('115% Thoáng'), findsOneWidget);

    await tester.tap(find.text('115% Thoáng'));
    await tester.pump();

    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(updatedScale, closeTo(1.15, 0.01));
  });
}
