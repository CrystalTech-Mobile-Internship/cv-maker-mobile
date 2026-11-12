import 'package:cv_maker_mobile/features/ai_tools/domain/models/ai_assistant_models.dart';
import 'package:cv_maker_mobile/features/ai_tools/domain/repositories/ai_assistant_repository.dart';
import 'package:cv_maker_mobile/features/ai_tools/presentation/controllers/ai_interview_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_ai_assistant_repository.dart';

void main() {
  test('appends the user message and the AI reply', () async {
    final repository = FakeAiAssistantRepository();
    final controller = AiInterviewController(repository);

    await controller.send('  Mình muốn làm Flutter  ');

    final messages = controller.state.messages;
    expect(messages, hasLength(3));
    expect(messages[1].role, AiChatRole.user);
    expect(messages[1].content, 'Mình muốn làm Flutter');
    expect(messages[2].content, 'Câu hỏi tiếp theo 1');
    expect(controller.state.progress, 30);
    expect(controller.state.canGenerate, isFalse);
  });

  test('allows generating after three answers', () async {
    final controller = AiInterviewController(FakeAiAssistantRepository());
    for (final answer in ['a', 'b', 'c']) {
      await controller.send(answer);
    }
    expect(controller.state.canGenerate, isTrue);
    final draft = await controller.generate();
    expect(draft?.targetRole, 'Flutter Developer');
  });

  test('keeps the conversation and exposes quota errors', () async {
    final repository = FakeAiAssistantRepository(
      failure: const AiWritingFailure(
        'Hết lượt',
        code: AiWritingFailureCode.quotaExceeded,
      ),
    );
    final controller = AiInterviewController(repository);

    await controller.send('Xin chào');

    expect(controller.state.messages.last.content, 'Xin chào');
    expect(controller.state.errorCode, AiWritingFailureCode.quotaExceeded);
    expect(controller.state.isSending, isFalse);
  });

  test('ignores blank messages', () async {
    final repository = FakeAiAssistantRepository();
    final controller = AiInterviewController(repository);
    await controller.send('   ');
    expect(repository.interviewCalls, isEmpty);
  });
}
