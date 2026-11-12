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
}
