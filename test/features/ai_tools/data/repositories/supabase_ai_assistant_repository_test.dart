import 'package:cv_maker_mobile/features/ai_tools/data/datasources/ai_writing_remote_data_source.dart';
import 'package:cv_maker_mobile/features/ai_tools/data/repositories/supabase_ai_assistant_repository.dart';
import 'package:cv_maker_mobile/features/ai_tools/domain/models/ai_assistant_models.dart';
import 'package:cv_maker_mobile/features/ai_tools/domain/repositories/ai_assistant_repository.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Handler =
    Future<Map<String, dynamic>> Function(
      String action,
      Map<String, dynamic> input,
    );

class _FakeRemote extends AiWritingRemoteDataSource {
  _FakeRemote(this.handler);

  final _Handler handler;
  final calls = <String>[];

  @override
  Future<Map<String, dynamic>> invoke(
    String action,
    Map<String, dynamic> input,
  ) {
    calls.add(action);
    return handler(action, input);
  }
}

const _quota = {'plan': 'free', 'used': 4, 'limit': 15, 'remaining': 11};

void main() {
  test('returns interview replies and publishes the quota', () async {
    AiQuota? published;
    final remote = _FakeRemote(
      (action, input) async => {
        'result': {'reply': 'Bạn học ở đâu?', 'progress': 40},
        'quota': _quota,
      },
    );
    final repository = SupabaseAiAssistantRepository(
      remote,
      onQuota: (quota) => published = quota,
    );

    final reply = await repository.interview(
      messages: const [AiChatMessage(role: AiChatRole.user, content: 'Hi')],
      language: 'vi',
    );

    expect(reply.reply, 'Bạn học ở đâu?');
    expect(reply.progress, 40);
    expect(remote.calls, ['interview']);
    expect(published?.remaining, 11);
    expect(repository.lastQuota?.used, 4);
  });

  test('maps quota exhaustion to a typed failure and keeps quota', () async {
    final repository = SupabaseAiAssistantRepository(
      _FakeRemote(
        (action, input) async => throw const AiWritingRemoteException(
          'Hết lượt',
          statusCode: 402,
          code: 'quota_exceeded',
          quota: {'plan': 'free', 'used': 15, 'limit': 15, 'remaining': 0},
        ),
      ),
    );

    await expectLater(
      repository.improveBullets(
        jobTitle: 'Dev',
        company: 'A',
        bullets: const ['x'],
        targetRole: '',
        language: 'vi',
      ),
      throwsA(
        isA<AiWritingFailure>().having(
          (failure) => failure.code,
          'code',
          AiWritingFailureCode.quotaExceeded,
        ),
      ),
    );
    expect(repository.lastQuota?.isExhausted, isTrue);
  });

  test('parses AI resume drafts and clips oversized text', () async {
    late Map<String, dynamic> sent;
    final repository = SupabaseAiAssistantRepository(
      _FakeRemote((action, input) async {
        sent = input;
        return {
          'result': {
            'cv': {
              'fullName': 'B',
              'skills': ['Git'],
            },
          },
        };
      }),
    );

    final draft = await repository.parseResume(
      sourceName: 'cv.pdf',
      text: List.filled(20000, 'a').join(),
      language: 'vi',
    );

    expect((sent['text'] as String).length, 14000);
    expect(draft.fullName, 'B');
    expect(draft.rawText.length, 20000);
  });

  test('treats malformed results as unavailable', () async {
    final repository = SupabaseAiAssistantRepository(
      _FakeRemote((action, input) async => {'result': 'oops'}),
    );
    await expectLater(
      repository.coverLetter(
        cvText: 'cv',
        jobDescription: 'jd',
        company: '',
        language: 'vi',
      ),
      throwsA(isA<AiWritingFailure>()),
    );
  });
}
