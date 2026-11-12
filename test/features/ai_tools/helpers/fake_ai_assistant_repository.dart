import 'package:cv_maker_mobile/features/ai_tools/domain/models/ai_assistant_models.dart';
import 'package:cv_maker_mobile/features/ai_tools/domain/repositories/ai_assistant_repository.dart';
import 'package:cv_maker_mobile/features/resume_import/domain/models/resume_import_draft.dart';

class FakeAiAssistantRepository implements AiAssistantRepository {
  FakeAiAssistantRepository({this.failure});

  AiWritingFailure? failure;
  final interviewCalls = <List<AiChatMessage>>[];
  bool readyAfterFirst = false;

  @override
  AiQuota? lastQuota;

  void _maybeFail() {
    final error = failure;
    if (error != null) throw error;
  }

  @override
  Future<AiQuota> fetchQuota() async =>
      const AiQuota(plan: 'free', used: 0, limit: 15, remaining: 15);

  @override
  Future<AiInterviewReply> interview({
    required List<AiChatMessage> messages,
    required String language,
  }) async {
    _maybeFail();
    interviewCalls.add(messages);
    return AiInterviewReply(
      reply: 'Câu hỏi tiếp theo ${interviewCalls.length}',
      progress: 30 * interviewCalls.length,
      readyToGenerate: readyAfterFirst,
    );
  }

  @override
  Future<ResumeImportDraft> generateCv({
    required List<AiChatMessage> messages,
    required String language,
  }) async {
    _maybeFail();
    return const ResumeImportDraft(
      sourceName: 'AI',
      rawText: '',
      fullName: 'Nguyễn Văn A',
      targetRole: 'Flutter Developer',
      email: '',
      phone: '',
      address: '',
      summary: 'Tóm tắt',
      skills: ['Flutter'],
      educations: [],
      experiences: [],
      projects: [],
      certifications: [],
      warnings: [],
    );
  }

  @override
  Future<ResumeImportDraft> parseResume({
    required String sourceName,
    required String text,
    required String language,
  }) => generateCv(messages: const [], language: language);

  @override
  Future<AiBulletSuggestion> improveBullets({
    required String jobTitle,
    required String company,
    required List<String> bullets,
    required String targetRole,
    required String language,
  }) async {
    _maybeFail();
    return AiBulletSuggestion(bullets: [for (final b in bullets) 'Đã $b']);
  }

  @override
  Future<String> coverLetter({
    required String cvText,
    required String jobDescription,
    required String company,
    required String language,
  }) async {
    _maybeFail();
    return 'Kính gửi nhà tuyển dụng';
  }
}
