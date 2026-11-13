import 'package:cv_maker_mobile/core/widgets/responsive_layout_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResponsiveLayoutBuilder', () {
    testWidgets('renders mobile layout when width is less than 600', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayoutBuilder(
            mobile: (context, constraints) => const Text('Mobile Layout'),
            desktop: (context, constraints) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('renders desktop layout when width is >= 900', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayoutBuilder(
            mobile: (context, constraints) => const Text('Mobile Layout'),
            desktop: (context, constraints) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Desktop Layout'), findsOneWidget);
      expect(find.text('Mobile Layout'), findsNothing);
    });

    testWidgets('renders tablet layout when width is between 600 and 899', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayoutBuilder(
            mobile: (context, constraints) => const Text('Mobile Layout'),
            tablet: (context, constraints) => const Text('Tablet Layout'),
            desktop: (context, constraints) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Tablet Layout'), findsOneWidget);
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });
  });

  group('WebConstrainedWidth', () {
    testWidgets('wraps child with maximum width constraint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WebConstrainedWidth(maxWidth: 800, child: Text('Content')),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(WebConstrainedWidth),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(constrainedBox.constraints.maxWidth, 800);
    });
  });
}
