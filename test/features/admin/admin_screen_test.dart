import 'dart:async';

import 'package:cv_maker_mobile/features/admin/data/supabase_admin_repository.dart';
import 'package:cv_maker_mobile/features/admin/domain/admin_models.dart';
import 'package:cv_maker_mobile/features/admin/presentation/admin_providers.dart';
import 'package:cv_maker_mobile/features/admin/presentation/admin_screen.dart';
import 'package:cv_maker_mobile/features/support/domain/support_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminRepository implements AdminRepository {
  final replies = <(String, String)>[];
  final reviews = <(String, bool)>[];
  final marked = <String>[];
  var unread = 2;

  @override
  Future<void> markRead(String userId) async {
    marked.add(userId);
    unread = 0;
  }

  @override
  Future<bool> isAdmin() async => true;

  @override
  Future<AdminStats> stats() async => const AdminStats(
    users: 12,
    proUsers: 3,
    monthRevenue: 168000,
    waitingThreads: 1,
    pendingRequests: 1,
  );

  @override
  Future<List<SupportThread>> threads() async => [
    SupportThread(
      userId: 'u1',
      displayName: 'Lan',
      email: 'lan@example.com',
      lastBody: 'Chưa nhận được Pro',
      lastFromSupport: false,
      lastAt: DateTime.utc(2026, 11, 20, 6),
      waiting: 2,
      unread: unread,
    ),
  ];

  @override
  Stream<void> supportChanges() => const Stream.empty();

  @override
  Stream<List<SupportMessage>> conversation(String userId) => Stream.value([
    SupportMessage(
      id: 'm1',
      fromSupport: false,
      body: 'Chưa nhận được Pro',
      createdAt: DateTime.utc(2026, 11, 20, 6),
    ),
  ]);

  @override
  Future<void> reply(String userId, String body) async =>
      replies.add((userId, body));

  @override
  Future<List<AdminProRequest>> proRequests() async => [
    AdminProRequest(
      id: 'r1',
      email: 'lan@example.com',
      plan: 'quarterly',
      amount: 119000,
      transferCode: 'CVPROQ1A2B3C4D',
      status: 'pending',
      createdAt: DateTime.utc(2026, 11, 20, 5),
    ),
  ];

  @override
  Future<List<AdminPaymentEvent>> paymentEvents() async => [
    AdminPaymentEvent(
      id: '1',
      amount: 119000,
      content: 'chuyen tien',
      status: 'unmatched',
      createdAt: DateTime.utc(2026, 11, 20, 5, 30),
    ),
  ];

  @override
  Future<void> reviewProRequest(
    String requestId, {
    required bool approve,
  }) async => reviews.add((requestId, approve));
}

Future<void> _pump(
  WidgetTester tester, {
  required bool admin,
  required AdminRepository repository,
  Size size = const Size(1200, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isAdminProvider.overrideWith((ref) async => admin),
        adminRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: AdminScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('non-admin accounts see no data', (tester) async {
    await _pump(tester, admin: false, repository: _FakeAdminRepository());

    expect(find.byKey(const Key('admin-not-allowed')), findsOneWidget);
    expect(find.text('Lan'), findsNothing);
  });

  testWidgets('admin reads a conversation and replies', (tester) async {
    final repository = _FakeAdminRepository();
    await _pump(tester, admin: true, repository: repository);

    expect(find.text('12'), findsOneWidget);
    expect(find.text('Hỗ trợ (1)'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-thread-u1')));
    await tester.pumpAndSettle();
    expect(find.text('lan@example.com'), findsOneWidget);

    // Opening the conversation marks it read: the badge goes, and it is
    // still flagged as not answered.
    expect(repository.marked, ['u1']);
    expect(find.text('2'), findsNothing);
    expect(find.text('Đã xem · chưa trả lời'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('admin-reply-input')),
      'Mình đã bật Pro cho bạn',
    );
    await tester.tap(find.byKey(const Key('admin-reply-send')));
    await tester.pumpAndSettle();

    expect(repository.replies, [('u1', 'Mình đã bật Pro cho bạn')]);
  });

  testWidgets('phone layout opens the conversation on its own page', (
    tester,
  ) async {
    await _pump(
      tester,
      admin: true,
      repository: _FakeAdminRepository(),
      size: const Size(360, 780),
    );

    await tester.tap(find.byKey(const Key('admin-thread-u1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-reply-input')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('approving a request asks first, then calls the server', (
    tester,
  ) async {
    final repository = _FakeAdminRepository();
    await _pump(tester, admin: true, repository: repository);

    await tester.tap(find.byKey(const Key('admin-tab-payments')));
    await tester.pumpAndSettle();
    expect(find.text('Không khớp'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-approve-r1')));
    await tester.pumpAndSettle();
    expect(repository.reviews, isEmpty);

    await tester.tap(find.byKey(const Key('admin-review-confirm')));
    await tester.pumpAndSettle();
    expect(repository.reviews, [('r1', true)]);
  });

  test('rows from the server parse safely', () {
    final thread = SupportThread.fromRow({
      'user_id': 'u1',
      'display_name': null,
      'email': 'a@b.c',
      'last_body': 'hi',
      'last_sender': 'support',
      'last_at': '2026-11-20T06:00:00Z',
      'waiting': 0,
    });
    expect(thread.lastFromSupport, isTrue);
    expect(thread.needsReply, isFalse);

    final stats = AdminStats.fromRow({'users': 5, 'month_revenue': '49000'});
    expect(stats.users, 5);
    expect(stats.monthRevenue, 49000);
    expect(stats.proUsers, 0);
  });
}
