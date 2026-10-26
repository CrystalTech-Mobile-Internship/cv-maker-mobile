import 'package:cv_maker_mobile/features/ai_tools/presentation/screens/ats_scorer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ATS scorer shows placeholder analysis UI', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AtsScorerScreen()));

    expect(find.text('Chấm điểm ATS'), findsOneWidget);
    expect(find.text('Chấm điểm CV theo JD'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Cần Flutter, Riverpod, SQLite và kinh nghiệm Clean Architecture.',
    );
    await tester.tap(find.text('Chấm điểm CV theo JD'));
    await tester.pump();

    expect(find.text('72%'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Riverpod'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Riverpod'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
  });
}
