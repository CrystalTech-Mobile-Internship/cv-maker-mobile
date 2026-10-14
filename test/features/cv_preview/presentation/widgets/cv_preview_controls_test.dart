import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_preview_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'preview controls fit an iPhone-sized viewport and emit changes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? selectedLanguage;
      double? selectedScale;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CvPreviewControls(
              language: 'vi',
              fontSizeScale: 1,
              onLanguageChanged: (value) => selectedLanguage = value,
              onFontSizeScaleChanged: (value) => selectedScale = value,
            ),
          ),
        ),
      );

      expect(find.text('🇻🇳 VI'), findsOneWidget);
      expect(
        find.byKey(const Key('font-size-percentage-field')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('decrease-font-size')), findsOneWidget);
      expect(find.byKey(const Key('increase-font-size')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('preview-language-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🇬🇧 EN').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('increase-font-size')));
      await tester.pump();

      expect(selectedLanguage, 'en');
      expect(selectedScale, 1.05);
      expect(tester.takeException(), isNull);
    },
  );
}
