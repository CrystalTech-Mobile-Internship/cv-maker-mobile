import 'dart:async';

import 'package:cv_maker_mobile/features/ai_tools/data/datasources/ai_writing_remote_data_source.dart';
import 'package:cv_maker_mobile/features/ai_tools/data/repositories/supabase_ai_writing_repository.dart';
import 'package:cv_maker_mobile/features/ai_tools/domain/models/summary_polish_request.dart';
import 'package:cv_maker_mobile/features/ai_tools/domain/repositories/ai_writing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _request = SummaryPolishRequest(
  currentSummary:
      'Flutter developer tập trung vào sản phẩm offline-first và trải nghiệm người dùng.',
  targetRole: 'Flutter Developer',
  language: 'vi',
  skills: ['Flutter', 'Dart'],
);

class _FakeRemoteDataSource extends AiWritingRemoteDataSource {
  _FakeRemoteDataSource(this.handler);

  final Future<Map<String, dynamic>> Function() handler;

  @override
  Future<Map<String, dynamic>> polishSummary(SummaryPolishRequest request) =>
      handler();
}

void main() {
  test('returns a typed result for a valid Edge Function response', () async {
    final repository = SupabaseAiWritingRepository(
      _FakeRemoteDataSource(
        () async => {
          'suggestedSummary':
              'Lập trình viên Flutter xây dựng sản phẩm offline-first ổn định.',
          'provider': 'Gemini',
        },
      ),
    );

    final result = await repository.polishSummary(_request);

    expect(result.provider, 'Gemini');
    expect(result.suggestedSummary, contains('offline-first'));
  });

  for (final testCase in <({int status, AiWritingFailureCode code})>[
    (status: 401, code: AiWritingFailureCode.notAuthenticated),
    (status: 422, code: AiWritingFailureCode.invalidInput),
    (status: 429, code: AiWritingFailureCode.rateLimited),
    (status: 503, code: AiWritingFailureCode.unavailable),
  ]) {
    test('maps HTTP ${testCase.status} to ${testCase.code.name}', () async {
      final repository = SupabaseAiWritingRepository(
        _FakeRemoteDataSource(
          () async => throw AiWritingRemoteException(
            'Lỗi an toàn từ backend.',
            statusCode: testCase.status,
          ),
        ),
      );

      await expectLater(
        repository.polishSummary(_request),
        throwsA(
          isA<AiWritingFailure>()
              .having((error) => error.code, 'code', testCase.code)
              .having(
                (error) => error.message,
                'message',
                'Lỗi an toàn từ backend.',
              ),
        ),
      );
    });
  }

  test('maps a missing Edge Function to a safe setup message', () async {
    final repository = SupabaseAiWritingRepository(
      _FakeRemoteDataSource(
        () async => throw const AiWritingRemoteException(
          'Requested function was not found.',
          statusCode: 404,
        ),
      ),
    );

    await expectLater(
      repository.polishSummary(_request),
      throwsA(
        isA<AiWritingFailure>()
            .having(
              (error) => error.code,
              'code',
              AiWritingFailureCode.unavailable,
            )
            .having(
              (error) => error.message,
              'message',
              contains('chưa dùng được'),
            ),
      ),
    );
  });

  test(
    'maps an Edge Function timeout without exposing implementation data',
    () async {
      final completer = Completer<Map<String, dynamic>>();
      final repository = SupabaseAiWritingRepository(
        _FakeRemoteDataSource(() => completer.future),
        timeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        repository.polishSummary(_request),
        throwsA(
          isA<AiWritingFailure>()
              .having(
                (error) => error.code,
                'code',
                AiWritingFailureCode.unavailable,
              )
              .having((error) => error.message, 'message', contains('quá lâu')),
        ),
      );
    },
  );
}
