import 'package:cv_maker_mobile/features/ai_tools/presentation/widgets/summary_polish_preview_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AI preview keeps original until the user applies suggestion', (
    tester,
  ) async {
    SummaryPolishPreviewAction? action;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                action = await showSummaryPolishPreviewSheet(
                  context: context,
                  original: 'Nội dung gốc an toàn.',
                  suggested: 'Nội dung AI chỉ là đề xuất.',
                  provider: 'Gemini',
                  isEnglish: false,
                );
              },
              child: const Text('Mở'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    expect(find.text('Nội dung gốc an toàn.'), findsOneWidget);
    expect(find.text('Nội dung AI chỉ là đề xuất.'), findsOneWidget);
    expect(action, isNull);

    await tester.tap(find.byKey(const Key('apply-ai-summary')));
    await tester.pumpAndSettle();
    expect(action, SummaryPolishPreviewAction.apply);
  });

  testWidgets('AI preview exposes retry without applying the suggestion', (
    tester,
  ) async {
    SummaryPolishPreviewAction? action;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                action = await showSummaryPolishPreviewSheet(
                  context: context,
                  original: 'Nội dung gốc an toàn.',
                  suggested: 'Nội dung đề xuất lần đầu.',
                  provider: 'Gemini',
                  isEnglish: false,
                );
              },
              child: const Text('Mở'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('retry-ai-summary')));
    await tester.pumpAndSettle();

    expect(action, SummaryPolishPreviewAction.retry);
  });
}
