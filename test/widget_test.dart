import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cv_maker_mobile/app/app.dart';

void main() {
  testWidgets('App smoke test launches without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CvMakerApp()));

    // GoRouter requires pumpAndSettle to resolve initial route
    await tester.pumpAndSettle();

    expect(find.text('Smart CV Maker'), findsOneWidget);
  });
}
