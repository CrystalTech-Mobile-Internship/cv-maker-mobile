import '../../../resume_import/domain/models/resume_import_draft.dart';

/// Converts the sanitized CV JSON returned by `cv-assistant` into the same
/// [ResumeImportDraft] used by the on-device importer, so AI results go
/// through the existing review dialog before anything is saved.
abstract final class AiCvDraftMapper {
  static ResumeImportDraft fromJson(
    Map<String, dynamic> json, {
    required String sourceName,
    required String rawText,
    DateTime? now,
  }) {
    final warnings = <String>['Hãy kiểm tra lại trước khi lưu.'];
    final fallbackStart = DateTime.utc((now ?? DateTime.now()).year);
    var missingDates = false;

    DateTime start(Object? value) {
      final parsed = _month(value);
      if (parsed == null) missingDates = true;
      return parsed ?? fallbackStart;
    }

    final educations = [
      for (final item in _maps(json['educations']))
        ResumeEducationDraft(
          institution: _text(item['institution']),
          degree: _text(item['degree']),
          fieldOfStudy: _text(item['fieldOfStudy']),
          startDate: start(item['startDate']),
          endDate: _month(item['endDate']),
          isCurrent: item['isCurrent'] == true,
          gpa: _nullable(item['gpa']),
          achievements: _texts(item['achievements']),
        ),
    ];
    final experiences = [
      for (final item in _maps(json['experiences']))
        ResumeExperienceDraft(
          jobTitle: _text(item['jobTitle']),
          company: _text(item['company']),
          startDate: start(item['startDate']),
          endDate: _month(item['endDate']),
          isCurrent: item['isCurrent'] == true,
          bulletPoints: _texts(item['bulletPoints']),
        ),
    ];
    if (missingDates) {
      warnings.add(
        'Một số mục chưa có thời gian bắt đầu; ứng dụng tạm điền năm hiện tại.',
      );
    }

    return ResumeImportDraft(
      sourceName: sourceName,
      rawText: rawText,
      fullName: _text(json['fullName']),
      targetRole: _text(json['targetRole']),
      email: _text(json['email']),
      phone: _text(json['phone']),
      address: _text(json['address']),
      summary: _text(json['summary']),
      skills: _texts(json['skills']).toSet().toList(growable: false),
      educations: educations,
      experiences: experiences,
      projects: [
        for (final item in _maps(json['projects']))
          ResumeProjectDraft(
            name: _text(item['name']),
            role: _text(item['role']),
            description: _text(item['description']),
            technologies: _texts(item['technologies']),
            sourceUrl: _nullable(item['sourceUrl']),
            startDate: _month(item['startDate']),
            endDate: _month(item['endDate']),
          ),
      ],
      certifications: [
        for (final item in _maps(json['certifications']))
          ResumeCertificationDraft(
            name: _text(item['name']),
            issuer: _text(item['issuer']),
            score: _nullable(item['score']),
            issueDate: _month(item['issueDate']),
            credentialUrl: _nullable(item['credentialUrl']),
          ),
      ],
      warnings: warnings,
    );
  }

  static List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static String _text(Object? value) =>
      value is String ? value.trim() : (value is num ? '$value' : '');

  static String? _nullable(Object? value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }

  static List<String> _texts(Object? value) {
    if (value is! List) return const [];
    return value
        .map(_text)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _month(Object? value) {
    final match = RegExp(r'^(\d{4})(?:-(\d{1,2}))?').firstMatch(_text(value));
    if (match == null) return null;
    final month = int.tryParse(match.group(2) ?? '1') ?? 1;
    return DateTime.utc(int.parse(match.group(1)!), month.clamp(1, 12));
  }
}
