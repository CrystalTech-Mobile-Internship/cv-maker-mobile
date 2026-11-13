import 'package:flutter/gestures.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_a4_design_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CvModel _cv({List<String> hidden = const ['certifications']}) =>
    CvModel.empty(id: 'cv-1').copyWith(
      summary: 'Backend developer who builds reliable services.',
      hiddenSections: hidden,
    );

Future<List<List<String>>> _pump(
  WidgetTester tester,
  CvModel cv,
  List<List<String>> calls,
) async {
  tester.view.physicalSize = const Size(1440, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CvA4DesignBoard(
          cv: cv,
          onLayoutChanged: (order, hidden) =>
              calls.add([...order, '|', ...hidden]),
        ),
      ),
    ),
  );
  return calls;
}

Future<void> _drag(WidgetTester tester, Finder from, Finder to) async {
  final gesture = await tester.startGesture(tester.getCenter(from));
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.moveTo(tester.getCenter(to));
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.moveTo(tester.getCenter(to) + const Offset(0, 1));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('drags a section from the palette onto the top of the page', (
    tester,
  ) async {
    final calls = await _pump(tester, _cv(), []);

    await _drag(
      tester,
      find.byKey(const ValueKey('design-palette-certifications')),
      find.byKey(const ValueKey('design-gap-0')),
    );

    expect(calls, isNotEmpty);
    expect(calls.last.first, 'certifications');
    expect(calls.last.last, '|', reason: 'nothing is hidden any more');
  });

  testWidgets('moves a section below another one on the page', (tester) async {
    final calls = await _pump(tester, _cv(hidden: const []), []);

    // Summary is first; drop it after projects (gap 3).
    await _drag(
      tester,
      find.byKey(const ValueKey('design-block-summary')),
      find.byKey(const ValueKey('design-gap-3')),
    );

    expect(calls.last.take(3), ['experience', 'projects', 'summary']);
  });

  testWidgets('dragging a section back to the palette removes it', (
    tester,
  ) async {
    final calls = await _pump(tester, _cv(hidden: const []), []);

    await _drag(
      tester,
      find.byKey(const ValueKey('design-block-skills')),
      find.byKey(const Key('design-palette')),
    );

    expect(calls.last.last, 'skills');
    expect(calls.last.contains('|'), isTrue);
  });

  testWidgets('the remove button takes a section off the page', (tester) async {
    final calls = await _pump(tester, _cv(hidden: const []), []);

    final block = find.byKey(const ValueKey('design-block-summary'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(block));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Gỡ khỏi trang').first);
    await tester.pumpAndSettle();

    expect(calls.last.last, 'summary');
  });
}
