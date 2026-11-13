import 'package:cv_maker_mobile/core/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _launcher() => MaterialApp(
  home: Builder(
    builder: (context) => TextButton(
      onPressed: () => showAppSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [AppSheetHandle(), Text('Nội dung')],
        ),
      ),
      child: const Text('Mở'),
    ),
  ),
);

void main() {
  testWidgets('phones get a bottom sheet with a grab bar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_launcher());
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Nội dung'), findsOneWidget);
  });

  testWidgets('computers get a centred dialog without a grab bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_launcher());
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Nội dung'), findsOneWidget);
    final panel = find
        .descendant(of: find.byType(Dialog), matching: find.byType(Material))
        .first;
    expect(tester.getSize(panel).width, lessThanOrEqualTo(640));
    final dialogCenter = tester.getCenter(panel);
    expect(dialogCenter.dx, closeTo(720, 1));
  });
}
