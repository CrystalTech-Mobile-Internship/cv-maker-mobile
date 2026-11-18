/// Daily AI credit budget returned by the server after every AI call.
class AiQuota {
  const AiQuota({
    required this.plan,
    required this.used,
    required this.limit,
    required this.remaining,
  });

  final String plan;
  final int used;
  final int limit;
  final int remaining;

  bool get isPro => plan == 'pro';
  bool get isExhausted => remaining <= 0;

  static AiQuota? tryParse(Object? value) {
    if (value is! Map) return null;
    int number(Object? raw) =>
        raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    return AiQuota(
      plan: value['plan'] == 'pro' ? 'pro' : 'free',
      used: number(value['used']),
      limit: number(value['limit']),
      remaining: number(value['remaining']),
    );
  }
}

enum AiChatRole { user, assistant }

class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final AiChatRole role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role.name, 'content': content};
}

class AiInterviewReply {
  const AiInterviewReply({
    required this.reply,
    required this.progress,
    required this.readyToGenerate,
  });

  final String reply;
  final int progress;
  final bool readyToGenerate;
}

class AiBulletSuggestion {
  const AiBulletSuggestion({required this.bullets, this.tips = const []});

  final List<String> bullets;
  final List<String> tips;
}

/// Credit costs mirrored from the server for display only; the server is the
/// source of truth and enforces them.
abstract final class AiCreditCost {
  static const interview = 1;
  static const generateCv = 3;
  static const parseResume = 2;
  static const polishSummary = 1;
  static const improveBullets = 1;
  static const coverLetter = 2;
  static const tailorCv = 3;
  static const interviewQuestions = 1;
  static const answerFeedback = 1;
  static const editSection = 1;
}

/// One piece of a CV section sent to the AI for rewriting.
class AiEditBlock {
  const AiEditBlock({
    required this.id,
    required this.title,
    required this.lines,
  });

  final String id;
  final String title;
  final List<String> lines;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'lines': lines};
}

/// Rewritten lines keyed by block id, plus a one-line note for the user.
class AiSectionEdit {
  const AiSectionEdit({required this.blocks, this.reply = ''});

  final Map<String, List<String>> blocks;
  final String reply;
}

/// AI proposal for tailoring a CV to one job description.
class AiTailorResult {
  const AiTailorResult({
    required this.summary,
    required this.skillsOrder,
    required this.missingSkills,
    required this.experienceBullets,
    this.notes = const [],
  });

  final String summary;

  /// Existing skill names, most relevant first.
  final List<String> skillsOrder;

  /// JD skills absent from the CV; only added if the user confirms.
  final List<String> missingSkills;

  /// Rewritten bullets keyed by experience id.
  final Map<String, List<String>> experienceBullets;
  final List<String> notes;
}

class AiInterviewQuestion {
  const AiInterviewQuestion({
    required this.question,
    this.focus = '',
    this.tip = '',
  });

  final String question;
  final String focus;
  final String tip;
}

class AiAnswerFeedback {
  const AiAnswerFeedback({
    required this.score,
    required this.sampleAnswer,
    this.strengths = const [],
    this.improvements = const [],
  });

  final int score;
  final String sampleAnswer;
  final List<String> strengths;
  final List<String> improvements;
}
