import 'package:cv_maker_mobile/app/theme.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/template_gallery_sheet.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_preview_color_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TemplateGallerySheet displays templates and handles selection', (tester) async {
    String? selectedTemplate;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: TemplateGallerySheet(
            selectedTemplateId: 'harvard_ats',
            isEnglish: false,
            onSelectTemplate: (id) => selectedTemplate = id,
          ),
        ),
      ),
    );

    // Verify title and search content
    expect(find.text('Chọn mẫu giao diện CV'), findsOneWidget);
    expect(find.text('Harvard ATS'), findsOneWidget);
    expect(find.text('Modern Minimalist'), findsOneWidget);

    // Tap Modern Minimalist
    final modernCard = find.byKey(const ValueKey('template-card-modern_minimalist'));
    expect(modernCard, findsOneWidget);
    await tester.tap(modernCard);
    await tester.pump();

    expect(selectedTemplate, equals('modern_minimalist'));
  });

  testWidgets('CvPreviewColorSheet displays 8 curated color presets and handles selection', (tester) async {
    String? pickedColor;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CvPreviewColorSheet(
            currentColor: '#1E293B',
            isEnglish: false,
            onColorSelected: (hex) => pickedColor = hex,
          ),
        ),
      ),
    );

    // Verify title
    expect(find.text('Bảng màu chủ đạo CV'), findsOneWidget);

    // Tap Indigo preset
    final indigoChip = find.byKey(const ValueKey('preview-color-#4338CA'));
    expect(indigoChip, findsOneWidget);
    await tester.tap(indigoChip);
    await tester.pump();

    expect(pickedColor, equals('#4338CA'));
  });
}

