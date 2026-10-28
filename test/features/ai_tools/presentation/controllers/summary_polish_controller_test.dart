import 'dart:async';

import 'package:cv_maker_mobile/features/ai_tools/domain/models/summary_polish_request.dart';
import 'package:cv_maker_mobile/features/ai_tools/domain/models/summary_polish_result.dart';
import 'package:cv_maker_mobile/features/ai_tools/domain/repositories/ai_writing_repository.dart';
import 'package:cv_maker_mobile/features/ai_tools/presentation/controllers/summary_polish_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAiWritingRepository implements AiWritingRepository {
  _FakeAiWritingRepository({this.result, this.failure});

  final SummaryPolishResult? result;
  final AiWritingFailure? failure;

  @override
  Future<SummaryPolishResult> polishSummary(
    SummaryPolishRequest request,
  ) async {
    if (failure case final value?) throw value;
    return result!;
  }
}
class _DeferredAiWritingRepository implements AiWritingRepository {
  final completer = Completer<SummaryPolishResult>();
  int calls = 0;

  @override
  Future<SummaryPolishResult> polishSummary(
    SummaryPolishRequest request,
  ) {
    calls++;
    return completer.future;
  }
}

const _request = SummaryPolishRequest(
  currentSummary:
      'Flutter developer tập trung vào sản phẩm offline-first và trải nghiệm người dùng.',
  targetRole: 'Flutter Developer',
  language: 'vi',
  skills: ['Flutter', 'Dart'],
);

void main() {
  test(
    'controller exposes a successful suggestion without mutating input',
    () async {
      const suggestion =
          'Lập trình viên Flutter có kinh nghiệm xây dựng ứng dụng offline-first và tối ưu trải nghiệm người dùng.';
      final controller = SummaryPolishController(
        _FakeAiWritingRepository(
          result: const SummaryPolishResult(
            suggestedSummary: suggestion,
            provider: 'Gemini',
          ),
        ),
      );
      addTearDown(controller.dispose);

      await controller.polish(_request);

      expect(controller.state.status, SummaryPolishStatus.success);
      expect(controller.state.suggestedSummary, suggestion);
      expect(controller.state.provider, 'Gemini');
      expect(_request.currentSummary, isNot(suggestion));
    },
  );

  test('controller maps repository failure to a safe UI state', () async {
    final controller = SummaryPolishController(
      _FakeAiWritingRepository(
        failure: const AiWritingFailure(
          'Bạn cần đăng nhập để sử dụng trợ lý AI.',
          code: AiWritingFailureCode.notAuthenticated,
        ),
      ),
    );
    addTearDown(controller.dispose);

    await controller.polish(_request);

    expect(controller.state.status, SummaryPolishStatus.failure);
    expect(
      controller.state.errorMessage,
      'Bạn cần đăng nhập để sử dụng trợ lý AI.',
    );
    expect(controller.state.suggestedSummary, isNull);
  });

  test('concurrent calls share one in-flight AI request', () async {
    final repository = _DeferredAiWritingRepository();
    final controller = SummaryPolishController(repository);
    addTearDown(controller.dispose);

    final first = controller.polish(_request);
    final second = controller.polish(_request);

    expect(identical(first, second), isTrue);
    expect(repository.calls, 1);

    repository.completer.complete(
      const SummaryPolishResult(
        suggestedSummary: 'Một kết quả duy nhất được chia sẻ cho cả hai lời gọi.',
        provider: 'Gemini',
      ),
    );
    final results = await Future.wait([first, second]);

    expect(results, everyElement(same(results.first)));
    expect(controller.state.status, SummaryPolishStatus.success);
  });
}
