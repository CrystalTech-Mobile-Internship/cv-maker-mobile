import 'dart:convert';

import 'package:cv_maker_mobile/features/job_tracker/data/prefs_job_application_repository.dart';
import 'package:cv_maker_mobile/features/job_tracker/domain/job_application.dart';
import 'package:cv_maker_mobile/features/job_tracker/presentation/job_tracker_controller.dart';
import 'package:cv_maker_mobile/features/job_tracker/presentation/job_tracker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('repository keeps valid rows and skips broken ones', () async {
    SharedPreferences.setMockInitialValues({
      PrefsJobApplicationRepository.storageKey: jsonEncode([
        {
          'id': 'a',
          'company': 'Acme',
          'role': 'Flutter Developer',
          'status': 'interview',
          'updatedAt': '2026-11-20T00:00:00Z',
        },
        {'id': 'broken'},
      ]),
    });

    final items = await PrefsJobApplicationRepository().load();

    expect(items, hasLength(1));
    expect(items.single.status, JobApplicationStatus.interview);
  });

  test(
    'controller adds, changes status and removes, saving each time',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(jobTrackerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await controller.add(company: ' Acme ', role: 'Tester');
      var items = container.read(jobTrackerProvider).value!;
      expect(items.single.company, 'Acme');
      expect(items.single.appliedOn, isNull);

      await controller.setStatus(items.single.id, JobApplicationStatus.applied);
      items = container.read(jobTrackerProvider).value!;
      expect(items.single.status, JobApplicationStatus.applied);
      expect(items.single.appliedOn, isNotNull);

      final saved = await PrefsJobApplicationRepository().load();
      expect(saved.single.status, JobApplicationStatus.applied);

      await controller.remove(items.single.id);
      expect(container.read(jobTrackerProvider).value, isEmpty);
      expect(await PrefsJobApplicationRepository().load(), isEmpty);
    },
  );

  testWidgets('empty tracker lets the user add a first job', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: JobTrackerScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('job-tracker-add-first')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('job-save')));
    await tester.pump();
    expect(find.text('Hãy nhập vị trí và tên công ty.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('job-role')), 'Mobile Dev');
    await tester.enterText(find.byKey(const Key('job-company')), 'Acme');
    await tester.tap(find.byKey(const Key('job-save')));
    await tester.pumpAndSettle();

    expect(find.text('Mobile Dev'), findsOneWidget);
    expect(find.text('Đang để ý'), findsWidgets);
  });
}
