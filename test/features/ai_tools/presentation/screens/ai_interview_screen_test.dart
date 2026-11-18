import 'package:cv_maker_mobile/features/ai_tools/presentation/controllers/ai_assistant_providers.dart';
import 'package:cv_maker_mobile/features/ai_tools/presentation/screens/ai_interview_screen.dart';
import 'package:cv_maker_mobile/features/auth/domain/models/auth_user.dart';
import 'package:cv_maker_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_ai_assistant_repository.dart';

void main() {
  Widget app(FakeAiAssistantRepository repository, {AuthUser? user}) {
    return ProviderScope(
      overrides: [
        aiAssistantRepositoryProvider.overrideWithValue(repository),
        currentAuthUserProvider.overrideWithValue(user),
      ],
      child: const MaterialApp(home: AiInterviewScreen()),
    );
  }

  testWidgets('greets the user and keeps generation disabled at start', (
    tester,
  ) async {
    await tester.pumpWidget(app(FakeAiAssistantRepository()));

    expect(find.textContaining('Chào bạn!'), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-create-offer')), findsNothing);
    expect(find.text('Trả lời thêm vài câu để tạo CV'), findsNothing);
    expect(find.byKey(const ValueKey('ai-chat-ats')), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-chat-practice')), findsOneWidget);
  });

  testWidgets('asks guests to sign in instead of calling AI', (tester) async {
    final repository = FakeAiAssistantRepository();
    await tester.pumpWidget(app(repository));

    await tester.enterText(
      find.byKey(const ValueKey('ai-chat-input')),
      'Xin chào',
    );
    await tester.tap(find.byKey(const ValueKey('ai-chat-send')));
    await tester.pumpAndSettle();

    expect(find.text('Cần đăng nhập'), findsOneWidget);
    expect(repository.interviewCalls, isEmpty);
  });

  testWidgets('signed-in users with consent chat with the AI', (tester) async {
    SharedPreferences.setMockInitialValues({'ai_data_consent_v1': true});
    final repository = FakeAiAssistantRepository();
    await tester.pumpWidget(
      app(
        repository,
        user: const AuthUser(
          id: 'u1',
          email: 'test@example.com',
          displayName: 'Test',
          provider: 'email',
          isEmailConfirmed: true,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('ai-chat-input')),
      'Mình muốn làm Flutter',
    );
    await tester.tap(find.byKey(const ValueKey('ai-chat-send')));
    await tester.pumpAndSettle();

    expect(repository.interviewCalls, hasLength(1));
    expect(find.text('Câu hỏi tiếp theo 1'), findsOneWidget);
  });

  testWidgets('asks to create the CV after enough answers; "Không" hides it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'ai_data_consent_v1': true});
    await tester.pumpWidget(
      app(
        FakeAiAssistantRepository(),
        user: const AuthUser(
          id: 'u1',
          email: 'test@example.com',
          displayName: 'Test',
          provider: 'email',
          isEmailConfirmed: true,
        ),
      ),
    );

    for (final answer in ['a', 'b', 'c']) {
      expect(find.byKey(const ValueKey('ai-create-offer')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('ai-chat-input')),
        answer,
      );
      await tester.tap(find.byKey(const ValueKey('ai-chat-send')));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const ValueKey('ai-create-offer')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Có'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ai-decline-cv')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-create-offer')), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('ai-chat-input')), 'd');
    await tester.tap(find.byKey(const ValueKey('ai-chat-send')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-create-offer')), findsOneWidget);
  });
}
