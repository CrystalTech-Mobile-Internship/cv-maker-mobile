import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/export_pdf_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'ExportPdfDialog renders and allows submitting custom file name',
    (tester) async {
      String? exportedName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportPdfDialog(
              initialFileName: 'CV_Nguyen_Tuan_Anh.pdf',
              isEnglish: false,
              onConfirm: (name) {
                exportedName = name;
              },
            ),
          ),
        ),
      );

      // Verify dialog title and default text
      expect(find.text('Xuất tệp PDF A4'), findsOneWidget);
      expect(find.text('CV_Nguyen_Tuan_Anh'), findsOneWidget);
      expect(find.text('.pdf'), findsOneWidget);
      expect(find.text('Lưu Offline'), findsOneWidget);

      // Enter a new custom name
      await tester.enterText(find.byType(TextField), 'My_Custom_Resume');
      await tester.tap(find.text('Lưu Offline'));
      await tester.pumpAndSettle();

      expect(exportedName, 'My_Custom_Resume.pdf');
    },
  );

  testWidgets('ExportPdfDialog validates empty input', (tester) async {
    String? exportedName;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExportPdfDialog(
            initialFileName: 'CV_Test.pdf',
            isEnglish: true,
            onConfirm: (name) {
              exportedName = name;
            },
          ),
        ),
      ),
    );

    expect(find.text('Export PDF File'), findsOneWidget);

    // Clear the text
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save Offline'));
    await tester.pumpAndSettle();

    expect(find.text('File name cannot be empty'), findsOneWidget);
    expect(exportedName, isNull);
  });
}
