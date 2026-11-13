import 'package:cv_maker_mobile/features/ai_tools/domain/models/ai_assistant_models.dart';
import 'package:cv_maker_mobile/features/ai_tools/domain/repositories/ai_assistant_repository.dart';
import 'package:cv_maker_mobile/features/ai_tools/presentation/controllers/interview_practice_controller.dart';
import 'package:cv_maker_mobile/features/ai_tools/presentation/widgets/ai_tailor_review_sheet.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_ai_assistant_repository.dart';

CvModel _cv() => CvModel.empty(id: 'cv-1').copyWith(
  title: 'CV Flutter',
  summary: 'Tóm tắt cũ',
  skills: const [
    SkillModel(id: 's1', name: 'Git', category: SkillCategory.hard),
    SkillModel(id: 's2', name: 'Flutter', category: SkillCategory.hard),
  ],
  experiences: [
    ExperienceModel(
      id: 'e1',
      jobTitle: 'Intern',
      company: 'A',
      startDate: DateTime.utc(2026),
      bulletPoints: const ['Làm app'],
    ),
  ],
);

void main() {
  group('applyTailoring', () {
    test('creates a tailored copy without touching the original', () {
      final original = _cv();
      final copy = applyTailoring(
        original,
        const AiTailorResult(
          summary: 'Tóm tắt mới',
          skillsOrder: ['Flutter', 'Unknown', 'Git'],
          missingSkills: ['Docker', 'Kubernetes'],
          experienceBullets: {
            'e1': ['Phát triển app CV bằng Flutter'],
            'ghost': ['x'],
          },
        ),
        newId: 'tailored-1',
        title: 'CV Flutter (tối ưu theo JD)',
        confirmedSkills: {'Docker'},
        now: DateTime.utc(2026, 11, 12),
      );

      expect(copy.id, 'tailored-1');
      expect(copy.summary, 'Tóm tắt mới');
      expect(copy.skills.map((s) => s.name), ['Flutter', 'Git', 'Docker']);
      expect(copy.experiences.single.bulletPoints, [
        'Phát triển app CV bằng Flutter',
      ]);
      expect(copy.isSynced, isFalse);
      expect(original.summary, 'Tóm tắt cũ');
      expect(original.skills.first.name, 'Git');
    });
  });

  group('InterviewPracticeController', () {
    test('loads questions and scores an answer', () async {
      final controller = InterviewPracticeController(
        FakeAiAssistantRepository(),
      );
      await controller.start(_cv(), jobDescription: 'JD');
      expect(controller.state.questions, hasLength(2));

      controller.updateAnswer('Em dùng Riverpod để tách logic khỏi widget.');
      await controller.evaluate(_cv());

      expect(controller.state.feedback[0]?.score, 7);
      expect(controller.state.averageScore, 7);

      controller.goTo(1);
      expect(controller.state.index, 1);
      expect(controller.state.current?.question, 'Vì sao bạn chọn Flutter?');
    });

    test('rejects very short answers without calling AI', () async {
      final controller = InterviewPracticeController(
        FakeAiAssistantRepository(),
      );
      await controller.start(_cv());
      controller.updateAnswer('ok');
      await controller.evaluate(_cv());

      expect(controller.state.feedback, isEmpty);
      expect(controller.state.errorCode, AiWritingFailureCode.invalidInput);
    });

    test('surfaces quota errors when loading questions', () async {
      final controller = InterviewPracticeController(
        FakeAiAssistantRepository(
          failure: const AiWritingFailure(
            'Hết lượt',
            code: AiWritingFailureCode.quotaExceeded,
          ),
        ),
      );
      await controller.start(_cv());
      expect(controller.state.hasQuestions, isFalse);
      expect(controller.state.errorCode, AiWritingFailureCode.quotaExceeded);
    });
  });
}
