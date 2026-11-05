import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_page_fit_sheet.dart';

void main() {
  testWidgets('CvPageFitSheet renders and selects 85% 1-page auto fit preset', (tester) async {
    double? updatedScale;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CvPageFitSheet(
            currentScale: 1.0,
            onScaleChanged: (val) => updatedScale = val,
            isEnglish: false,
          ),
        ),
      ),
    );

    expect(find.text('Tối ưu bố cục & Căn chỉnh 1 trang'), findsOneWidget);
    expect(find.byKey(const Key('preset-85')), findsOneWidget);

    await tester.tap(find.byKey(const Key('preset-85')));
    await tester.pumpAndSettle();

    expect(updatedScale, 0.85);
  });
}

