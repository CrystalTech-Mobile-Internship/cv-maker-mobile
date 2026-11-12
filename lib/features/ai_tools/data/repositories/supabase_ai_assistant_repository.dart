import 'dart:async';

import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../resume_import/domain/models/resume_import_draft.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../datasources/ai_writing_remote_data_source.dart';
import '../mappers/ai_cv_draft_mapper.dart';
import 'supabase_ai_writing_repository.dart' show aiFailureCodeForStatus;

class SupabaseAiAssistantRepository implements AiAssistantRepository {
  SupabaseAiAssistantRepository(
    this._remote, {
    Duration timeout = const Duration(seconds: 90),
    void Function(AiQuota quota)? onQuota,
  }) : _timeout = timeout,
       _onQuota = onQuota;

  final AiWritingRemoteDataSource _remote;
  final Duration _timeout;
  final void Function(AiQuota quota)? _onQuota;
  AiQuota? _lastQuota;

  @override
  AiQuota? get lastQuota => _lastQuota;

  @override
  Future<AiQuota> fetchQuota() async {
    await _call('quota', const {});
    final quota = _lastQuota;
    if (quota == null) {
      throw const AiWritingFailure(
        'Chưa đọc được hạn mức AI.',
        code: AiWritingFailureCode.unavailable,
      );
    }
    return quota;
  }

  @override
  Future<AiInterviewReply> interview({
    required List<AiChatMessage> messages,
    required String language,
  }) async {
    final result = await _result('interview', {
      'language': language,
      'messages': _trim(messages),
    });
    final reply = (result['reply'] as String? ?? '').trim();
    if (reply.isEmpty) throw _emptyResult();
    return AiInterviewReply(
      reply: reply,
      progress: (result['progress'] as num? ?? 0).toInt().clamp(0, 100),
      readyToGenerate: result['readyToGenerate'] == true,
    );
  }

  @override
  Future<ResumeImportDraft> generateCv({
    required List<AiChatMessage> messages,
    required String language,
  }) async {
    final result = await _result('generate_cv', {
      'language': language,
      'messages': _trim(messages),
    });
    return _draft(result, sourceName: 'Trò chuyện với AI', rawText: '');
  }

  @override
  Future<ResumeImportDraft> parseResume({
    required String sourceName,
    required String text,
    required String language,
  }) async {
    final clipped = text.length > 14000 ? text.substring(0, 14000) : text;
    final result = await _result('parse_resume', {
      'language': language,
      'text': clipped,
    });
    return _draft(result, sourceName: sourceName, rawText: text);
  }

  @override
  Future<AiBulletSuggestion> improveBullets({
    required String jobTitle,
    required String company,
    required List<String> bullets,
    required String targetRole,
    required String language,
  }) async {
    final result = await _result('improve_bullets', {
      'jobTitle': jobTitle,
      'company': company,
      'bullets': bullets,
      'targetRole': targetRole,
      'language': language,
    });
    final suggested = _strings(result['bullets']);
    if (suggested.isEmpty) throw _emptyResult();
    return AiBulletSuggestion(
      bullets: suggested,
      tips: _strings(result['tips']),
    );
  }

  @override
  Future<String> coverLetter({
    required String cvText,
    required String jobDescription,
    required String company,
    required String language,
  }) async {
    final result = await _result('cover_letter', {
      'cv': cvText,
      'jobDescription': jobDescription,
      'company': company,
      'language': language,
    });
    final text = (result['text'] as String? ?? '').trim();
    if (text.isEmpty) throw _emptyResult();
    return text;
  }

  @override
  Future<AiTailorResult> tailorCv({
    required CvModel cv,
    required String jobDescription,
  }) async {
    final result = await _result('tailor_cv', {
      'language': cv.language,
      'targetRole': cv.personalInfo.targetRole,
      'summary': cv.summary,
      'skills': [for (final s in cv.skills) s.name],
      'experiences': [
        for (final e in cv.experiences.take(8))
          {
            'id': e.id,
            'title': '${e.jobTitle} - ${e.company}',
            'bullets': e.bulletPoints,
          },
      ],
      'jobDescription': jobDescription,
    });
    final bullets = <String, List<String>>{};
    final experiences = result['experiences'];
    if (experiences is List) {
      for (final item in experiences.whereType<Map>()) {
        final id = item['id']?.toString() ?? '';
        final lines = _strings(item['bullets']);
        if (id.isNotEmpty && lines.isNotEmpty) bullets[id] = lines;
      }
    }
    final summary = (result['summary'] as String? ?? '').trim();
    if (summary.isEmpty && bullets.isEmpty) throw _emptyResult();
    return AiTailorResult(
      summary: summary,
      skillsOrder: _strings(result['skillsOrder']),
      missingSkills: _strings(result['missingSkills']),
      experienceBullets: bullets,
      notes: _strings(result['notes']),
    );
  }

  @override
  Future<List<AiInterviewQuestion>> interviewQuestions({
    required String cvText,
    required String jobDescription,
    required String language,
  }) async {
    final result = await _result('interview_questions', {
      'cv': cvText,
      'jobDescription': jobDescription,
      'language': language,
    });
    final raw = result['questions'];
    final questions = <AiInterviewQuestion>[
      if (raw is List)
        for (final item in raw.whereType<Map>())
          if ((item['question'] as String? ?? '').trim().isNotEmpty)
            AiInterviewQuestion(
              question: (item['question'] as String).trim(),
              focus: (item['focus'] as String? ?? '').trim(),
              tip: (item['tip'] as String? ?? '').trim(),
            ),
    ];
    if (questions.isEmpty) throw _emptyResult();
    return questions;
  }

  @override
  Future<AiAnswerFeedback> answerFeedback({
    required String question,
    required String answer,
    required String cvText,
    required String language,
  }) async {
    final result = await _result('answer_feedback', {
      'question': question,
      'answer': answer,
      'cv': cvText,
      'language': language,
    });
    final sample = (result['sampleAnswer'] as String? ?? '').trim();
    if (sample.isEmpty) throw _emptyResult();
    return AiAnswerFeedback(
      score: (result['score'] as num? ?? 1).toInt().clamp(1, 10),
      sampleAnswer: sample,
      strengths: _strings(result['strengths']),
      improvements: _strings(result['improvements']),
    );
  }

  // ------------------------------------------------------------- internals

  /// Keeps the last 24 turns: enough context, bounded cost and payload.
  List<Map<String, dynamic>> _trim(List<AiChatMessage> messages) {
    final start = messages.length > 24 ? messages.length - 24 : 0;
    return [for (final m in messages.sublist(start)) m.toJson()];
  }

  ResumeImportDraft _draft(
    Map<String, dynamic> result, {
    required String sourceName,
    required String rawText,
  }) {
    final cv = result['cv'];
    if (cv is! Map) throw _emptyResult();
    return AiCvDraftMapper.fromJson(
      Map<String, dynamic>.from(cv),
      sourceName: sourceName,
      rawText: rawText,
    );
  }

  Future<Map<String, dynamic>> _result(
    String action,
    Map<String, dynamic> input,
  ) async {
    final data = await _call(action, input);
    final result = data['result'];
    if (result is! Map) throw _emptyResult();
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> _call(
    String action,
    Map<String, dynamic> input,
  ) async {
    try {
      final data = await _remote.invoke(action, input).timeout(_timeout);
      _remember(data['quota']);
      return data;
    } on AiWritingRemoteException catch (error) {
      _remember(error.quota);
      throw AiWritingFailure(
        error.message,
        code: aiFailureCodeForStatus(error.statusCode),
        cause: error,
      );
    } on TimeoutException catch (error) {
      throw AiWritingFailure(
        'AI phản hồi quá lâu. Hãy thử lại sau.',
        code: AiWritingFailureCode.unavailable,
        cause: error,
      );
    }
  }

  void _remember(Object? raw) {
    final quota = AiQuota.tryParse(raw);
    if (quota == null) return;
    _lastQuota = quota;
    _onQuota?.call(quota);
  }

  static List<String> _strings(Object? value) => value is List
      ? value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
      : const [];

  static AiWritingFailure _emptyResult() => const AiWritingFailure(
    'AI chưa tạo được nội dung phù hợp. Hãy thử lại.',
    code: AiWritingFailureCode.unavailable,
  );
}
