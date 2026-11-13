import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../resume_import/domain/models/resume_import_draft.dart';
import '../models/ai_assistant_models.dart';

export 'ai_writing_repository.dart' show AiWritingFailure, AiWritingFailureCode;

/// AI capabilities backed by the `cv-assistant` Edge Function. Every call
/// requires a signed-in user and consumes server-side daily credits.
abstract interface class AiAssistantRepository {
  /// Last quota reported by the server in this session, if any.
  AiQuota? get lastQuota;

  Future<AiQuota> fetchQuota();

  /// Reads the text of a public job posting page (no credit used).
  Future<String> fetchJobPosting(String url);

  Future<AiInterviewReply> interview({
    required List<AiChatMessage> messages,
    required String language,
  });

  Future<ResumeImportDraft> generateCv({
    required List<AiChatMessage> messages,
    required String language,
  });

  Future<ResumeImportDraft> parseResume({
    required String sourceName,
    required String text,
    required String language,
  });

  Future<AiBulletSuggestion> improveBullets({
    required String jobTitle,
    required String company,
    required List<String> bullets,
    required String targetRole,
    required String language,
  });

  Future<String> coverLetter({
    required String cvText,
    required String jobDescription,
    required String company,
    required String language,
  });

  Future<AiTailorResult> tailorCv({
    required CvModel cv,
    required String jobDescription,
  });

  Future<List<AiInterviewQuestion>> interviewQuestions({
    required String cvText,
    required String jobDescription,
    required String language,
  });

  Future<AiAnswerFeedback> answerFeedback({
    required String question,
    required String answer,
    required String cvText,
    required String language,
  });
}
