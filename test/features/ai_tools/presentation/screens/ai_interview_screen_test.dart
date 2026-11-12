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
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('ai-generate-cv')),
    );
    expect(button.onPressed, isNull);
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

    expect(find.text('Đăng nhập để dùng AI'), findsOneWidget);
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
}
