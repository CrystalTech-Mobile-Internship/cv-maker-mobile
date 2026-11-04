import 'package:cv_maker_mobile/features/cv_management/presentation/widgets/local_data_tools_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('backup tools fit a narrow phone and expose both actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var exportCount = 0;
    var restoreCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalDataToolsCard(
            onExport: () => exportCount++,
            onRestore: () => restoreCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('export-all-cvs')));
    await tester.tap(find.byKey(const Key('restore-cv-backup')));

    expect(exportCount, 1);
    expect(restoreCount, 1);
    expect(tester.takeException(), isNull);
  });
}
