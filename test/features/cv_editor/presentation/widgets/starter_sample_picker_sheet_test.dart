import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/starter_sample_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StarterSamplePickerSheet allows selecting summary and sample items', (tester) async {
    String? selectedSummary;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                StarterSamplePickerSheet.show(
                  context: context,
                  language: 'vi',
                  onSelectSummary: (summary) => selectedSummary = summary,
                );
              },
              child: const Text('Open Starter Samples'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Starter Samples'));
    await tester.pumpAndSettle();

    expect(find.text('Mẫu gợi ý nội dung có sẵn'), findsOneWidget);
    expect(find.text('Sinh viên CNTT / Fresher tốt nghiệp'), findsOneWidget);

    // Apply first summary sample
    final applyButtons = find.text('Sử dụng mẫu này');
    expect(applyButtons, findsWidgets);
    await tester.tap(applyButtons.first);
    await tester.pumpAndSettle();

    expect(selectedSummary, isNotNull);
    expect(selectedSummary, contains('Cử nhân Công nghệ Thông tin'));
  });
}
