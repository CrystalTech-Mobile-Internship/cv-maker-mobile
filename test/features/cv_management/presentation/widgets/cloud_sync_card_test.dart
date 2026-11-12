import 'package:cv_maker_mobile/features/cv_management/presentation/widgets/cloud_sync_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the active cloud destination without narrow overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CloudSyncCard(
            isSignedIn: true,
            localCount: 5,
            pendingCount: 2,
            backendLabel: 'Máy chủ phụ',
            isSyncing: false,
            onSync: () {},
            onLogin: () {},
          ),
        ),
      ),
    );

    expect(find.text('Sao lưu vào: Máy chủ phụ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
