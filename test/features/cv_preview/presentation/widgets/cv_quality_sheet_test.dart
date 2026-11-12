import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_quality_checker.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_interactive_section_reorder.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_quality_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('quality check button opens the report sheet', (tester) async {
    tester.view.physicalSize = const Size(840, 1720);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final cv = CvModel.empty(id: 'cv');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => CvInteractiveSectionReorder(
              cv: cv,
              language: 'vi',
              onOrderChanged: (_) {},
              onCheckQuality: () => showCvQualitySheet(
                context,
                report: CvQualityChecker.check(cv),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('preview-quality-check-btn')));
    await tester.pumpAndSettle();

    expect(find.text('Kiểm tra chất lượng CV'), findsOneWidget);
    expect(find.textContaining('vấn đề quan trọng'), findsOneWidget);
  });
}
