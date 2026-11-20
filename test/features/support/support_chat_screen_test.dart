import 'dart:async';

import 'package:cv_maker_mobile/features/auth/domain/models/auth_user.dart';
import 'package:cv_maker_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:cv_maker_mobile/features/support/data/supabase_support_repository.dart';
import 'package:cv_maker_mobile/features/support/domain/support_models.dart';
import 'package:cv_maker_mobile/features/support/presentation/support_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSupport implements SupportRepository {
  final _controller = StreamController<List<SupportMessage>>.broadcast();
  final _messages = <SupportMessage>[];
  final sent = <String>[];

  @override
  Stream<List<SupportMessage>> watch() async* {
    yield List.of(_messages);
    yield* _controller.stream;
  }

  @override
  Future<void> send(String body) async {
    sent.add(body);
    _messages.add(
      SupportMessage(
        id: 'm${_messages.length}',
        fromSupport: false,
        body: body,
        createdAt: DateTime.utc(2026, 11, 20, 8),
      ),
    );
    _controller.add(List.of(_messages));
  }

  void reply(String body) {
    _messages.add(
      SupportMessage(
        id: 'r${_messages.length}',
        fromSupport: true,
        body: body,
        createdAt: DateTime.utc(2026, 11, 20, 9),
      ),
    );
    _controller.add(List.of(_messages));
  }
}

Widget _app(_FakeSupport support, {AuthUser? user}) => ProviderScope(
  overrides: [
    supportRepositoryProvider.overrideWithValue(support),
    currentAuthUserProvider.overrideWithValue(user),
  ],
  child: const MaterialApp(home: SupportChatScreen()),
);

const _user = AuthUser(
  id: 'user-1',
  email: 'user@example.com',
  displayName: 'User',
  provider: 'email',
  isEmailConfirmed: true,
);

void main() {
  testWidgets('guests are asked to sign in first', (tester) async {
    await tester.pumpWidget(_app(_FakeSupport()));
    expect(find.text('Đăng nhập để nhắn hỗ trợ'), findsOneWidget);
    expect(find.byKey(const Key('support-input')), findsNothing);
  });

  testWidgets('sends a message and shows the reply', (tester) async {
    final support = _FakeSupport();
    await tester.pumpWidget(_app(support, user: _user));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('support-input')),
      'Tôi chưa nhận được Pro',
    );
    await tester.tap(find.byKey(const Key('support-send')));
    await tester.pump();
    await tester.pump();

    expect(support.sent, ['Tôi chưa nhận được Pro']);
    expect(find.text('Tôi chưa nhận được Pro'), findsOneWidget);

    support.reply('Đã kích hoạt cho bạn.');
    await tester.pump();
    expect(find.text('Đã kích hoạt cho bạn.'), findsOneWidget);
  });
}
