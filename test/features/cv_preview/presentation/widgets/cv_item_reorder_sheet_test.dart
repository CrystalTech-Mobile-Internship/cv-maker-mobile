import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_item_order_service.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_item_reorder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sorts newest first and returns the new order', (tester) async {
    List<String>? result;
    final items = [
      CvItemSummary(id: 'a', title: 'Cũ', sortDate: DateTime.utc(2020)),
      CvItemSummary(id: 'b', title: 'Mới', sortDate: DateTime.utc(2024)),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showCvItemReorderSheet(
                  context,
                  sectionTitle: 'Kinh nghiệm',
                  items: items,
                  isEnglish: false,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final apply = find.byKey(const ValueKey('item-reorder-apply'));
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('item-sort-newest')));
    await tester.pumpAndSettle();
    await tester.tap(apply);
    await tester.pumpAndSettle();

    expect(result, ['b', 'a']);
  });
}
