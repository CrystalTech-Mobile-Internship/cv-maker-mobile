import 'package:cv_maker_mobile/features/cv_editor/domain/models/cloud_sync_preview.dart';
import 'package:cv_maker_mobile/features/cv_management/presentation/widgets/cloud_sync_preview_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CloudSyncPreviewSheet displays metrics and invokes callbacks', (tester) async {
    var confirmed = false;
    var backupRequested = false;

    const preview = CloudSyncPreview(
      targetBackend: 'Supabase Primary',
      userEmail: 'tuananh@example.com',
      pendingUploadCount: 2,
      pendingDownloadCount: 1,
      conflictCount: 0,
      pendingDeletionCount: 0,
      localCvCount: 3,
      remoteCvCount: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CloudSyncPreviewSheet(
            preview: preview,
            onConfirmSync: () => confirmed = true,
            onExportBackup: () => backupRequested = true,
          ),
        ),
      ),
    );

    expect(find.text('Xem trước đồng bộ Cloud'), findsOneWidget);
    expect(find.text('tuananh@example.com'), findsOneWidget);
    expect(find.text('Supabase Primary'), findsOneWidget);
    expect(find.text('Tải lên Cloud'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Tải về máy'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Tap backup button
    await tester.tap(find.text('Sao lưu JSON ra máy tính trước'));
    await tester.pump();
    expect(backupRequested, isTrue);

    // Tap confirm button
    await tester.tap(find.byKey(const Key('confirm-cloud-sync-btn')));
    await tester.pump();
    expect(confirmed, isTrue);
  });

  testWidgets('CloudSyncPreviewSheet displays conflict warning and disables button on error', (tester) async {
    const preview = CloudSyncPreview(
      targetBackend: 'Supabase Secondary',
      userEmail: 'user@example.com',
      pendingUploadCount: 0,
      pendingDownloadCount: 0,
      conflictCount: 0,
      pendingDeletionCount: 0,
      localCvCount: 1,
      remoteCvCount: 0,
      errorMessage: 'Lỗi xác thực RLS',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CloudSyncPreviewSheet(
            preview: preview,
            onConfirmSync: () {},
            onExportBackup: () {},
          ),
        ),
      ),
    );

    expect(find.text('Lỗi xác thực RLS'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-cloud-sync-btn')),
    );
    expect(button.onPressed, isNull);
  });
}
