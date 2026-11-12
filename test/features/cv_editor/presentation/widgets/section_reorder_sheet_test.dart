import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/section_reorder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SectionReorderSheet displays all sections and triggers order change', (tester) async {
    List<String>? changedOrder;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                SectionReorderSheet.show(
                  context: context,
                  currentOrder: const [
                    'summary',
                    'experience',
                    'projects',
                    'education',
                    'skills',
                    'certifications',
                  ],
                  language: 'vi',
                  onOrderChanged: (newOrder) => changedOrder = newOrder,
                );
              },
              child: const Text('Open Reorder'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Reorder'));
    await tester.pumpAndSettle();

    // Verify header and titles
    expect(find.text('Sắp xếp bố cục mục CV'), findsOneWidget);
    expect(find.text('Mục tiêu nghề nghiệp'), findsOneWidget);
    expect(find.text('Kinh nghiệm làm việc'), findsOneWidget);
    expect(find.text('Dự án nổi bật'), findsOneWidget);

    // Tap move down on the first item (summary)
    final downButtons = find.byTooltip('Di chuyển xuống');
    expect(downButtons, findsWidgets);
    await tester.tap(downButtons.first);
    await tester.pumpAndSettle();

    expect(changedOrder, isNotNull);
    expect(changedOrder!.first, 'experience');
    expect(changedOrder![1], 'summary');

    // Tap Done
    await tester.tap(find.text('Xong & Áp dụng thay đổi'));
    await tester.pumpAndSettle();
    expect(find.text('Sắp xếp bố cục mục CV'), findsNothing);
  });
}
