import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/widgets/ats_action_verbs_sheet.dart';

void main() {
  testWidgets('AtsActionVerbsSheet renders and calls onInsertVerb', (tester) async {
    String? insertedVerb;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AtsActionVerbsSheet(
            language: 'vi',
            onInsertVerb: (v) => insertedVerb = v,
          ),
        ),
      ),
    );

    expect(find.text('Gợi ý động từ mạnh cho CV'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    final insertBtn = find.byKey(const Key('insert-verb-Phát triển'));
    expect(insertBtn, findsOneWidget);

    await tester.tap(insertBtn);
    await tester.pumpAndSettle();

    expect(insertedVerb, 'Phát triển');
  });
}

