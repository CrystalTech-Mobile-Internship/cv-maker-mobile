import '../../domain/models/resume_import_draft.dart';

final class ResumeTextParser {
  const ResumeTextParser();

  ResumeImportDraft parse({required String sourceName, required String text}) {
    final normalized = text
        .replaceAll('\r', '')
        .replaceAll(RegExp(r'[\t\u00A0]+'), ' ')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();
    final lines = normalized
        .split('\n')
        .map(_cleanLine)
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    final email =
        RegExp(
          r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
          caseSensitive: false,
        ).firstMatch(normalized)?.group(0) ??
        '';
    final phone =
        RegExp(
          r'(?<!\d)(?:\+?84|0)(?:[ .-]?\d){8,10}(?!\d)',
        ).firstMatch(normalized)?.group(0)?.replaceAll(RegExp(r'\s+'), ' ') ??
        '';

    final headings = <String>{
      'summary',
      'profile',
      'objective',
      'about me',
      'professional summary',
      'tóm tắt',
      'mục tiêu nghề nghiệp',
      'giới thiệu',
      'education',
      'học vấn',
      'experience',
      'work experience',
      'kinh nghiệm',
      'skills',
      'kỹ năng',
      'projects',
      'dự án',
      'certifications',
      'chứng chỉ',
    };
    final identityLines = lines
        .where(
          (line) =>
              !line.contains('@') && (phone.isEmpty || !line.contains(phone)),
        )
        .where((line) => !headings.contains(_headingKey(line)))
        .take(2)
        .toList(growable: false);

    final summary = _section(
      lines,
      starts: const {
        'summary',
        'profile',
        'objective',
        'about me',
        'professional summary',
        'tóm tắt',
        'mục tiêu nghề nghiệp',
        'giới thiệu',
      },
      allHeadings: headings,
    ).join(' ');
    final skillLines = _section(
      lines,
      starts: const {'skills', 'kỹ năng'},
      allHeadings: headings,
    );
    final skills = skillLines
        .expand((line) => line.split(RegExp(r'[,;|•·]')))
        .map((skill) => skill.trim())
        .where((skill) => skill.length >= 2 && skill.length <= 48)
        .take(18)
        .toSet()
        .toList(growable: false);

    final educationLines = _section(
      lines,
      starts: const {'education', 'học vấn'},
      allHeadings: headings,
    );
    final experienceLines = _section(
      lines,
      starts: const {'experience', 'work experience', 'kinh nghiệm'},
      allHeadings: headings,
    );
    final projectLines = _section(
      lines,
      starts: const {'projects', 'dự án'},
      allHeadings: headings,
    );
    final certificationLines = _section(
      lines,
      starts: const {'certifications', 'chứng chỉ'},
      allHeadings: headings,
    );
    final educations = _parseEducations(educationLines);
    final experiences = _parseExperiences(experienceLines);
    final projects = _parseProjects(projectLines);
    final certifications = _parseCertifications(certificationLines);

    final warnings = <String>[
      if (normalized.length < 80)
        'Tệp có rất ít chữ. Nếu đây là CV scan, ứng dụng chưa hỗ trợ OCR.',
      if (summary.isEmpty)
        'Chưa nhận diện chắc chắn phần tóm tắt; bạn có thể bổ sung trong Editor.',
      if (skills.isEmpty) 'Chưa nhận diện được danh sách kỹ năng.',
      if (educationLines.isNotEmpty && educations.isEmpty)
        'Có nội dung học vấn nhưng chưa đủ ngày tháng để tự điền an toàn.',
      if (experienceLines.isNotEmpty && experiences.isEmpty)
        'Có nội dung kinh nghiệm nhưng chưa đủ ngày tháng để tự điền an toàn.',
      'Hãy kiểm tra lại dữ liệu trước khi lưu; định dạng CV cũ có thể khác nhau.',
    ];

    return ResumeImportDraft(
      sourceName: sourceName,
      rawText: normalized,
      fullName: identityLines.isEmpty ? '' : identityLines.first,
      targetRole: identityLines.length < 2 ? '' : identityLines[1],
      email: email,
      phone: phone,
      address: '',
      summary: summary,
      skills: skills,
      educations: educations,
      experiences: experiences,
      projects: projects,
      certifications: certifications,
      warnings: warnings,
    );
  }

  static String _cleanLine(String value) =>
      value.replaceFirst(RegExp(r'^[\s•·▪◦●○\-–—]+'), '').trim();

  static String _headingKey(String value) =>
      value.toLowerCase().replaceAll(':', '').trim();

  static List<String> _section(
    List<String> lines, {
    required Set<String> starts,
    required Set<String> allHeadings,
  }) {
    final start = lines.indexWhere(
      (line) => starts.contains(_headingKey(line)),
    );
    if (start < 0) return const [];
    final result = <String>[];
    for (var index = start + 1; index < lines.length; index++) {
      if (allHeadings.contains(_headingKey(lines[index]))) break;
      result.add(lines[index]);
    }
    return result.take(12).toList(growable: false);
  }

  static List<ResumeEducationDraft> _parseEducations(List<String> lines) {
    return _entries(lines)
        .expand((entry) {
          final dates = _dateRange(entry.join(' '));
          if (dates?.start == null) return const <ResumeEducationDraft>[];
          final header = _headerParts(entry.first);
          final gpa = RegExp(
            r'(?:GPA|điểm trung bình)\s*[: ]\s*([0-9]+(?:[.,][0-9]+)?(?:\s*/\s*[0-9]+(?:[.,][0-9]+)?)?)',
            caseSensitive: false,
          ).firstMatch(entry.join(' '))?.group(1);
          return [
            ResumeEducationDraft(
              institution: header.isEmpty ? '' : header.first,
              degree: header.length > 1 ? header[1] : '',
              fieldOfStudy: header.length > 2 ? header[2] : '',
              startDate: dates!.start!,
              endDate: dates.end,
              isCurrent: dates.isCurrent,
              gpa: gpa,
              achievements: entry
                  .skip(1)
                  .where((line) => !_containsDate(line) && !_isGpaLine(line))
                  .toList(growable: false),
            ),
          ];
        })
        .toList(growable: false);
  }

  static List<ResumeExperienceDraft> _parseExperiences(List<String> lines) {
    return _entries(lines)
        .expand((entry) {
          final dates = _dateRange(entry.join(' '));
          if (dates?.start == null) return const <ResumeExperienceDraft>[];
          final header = _headerParts(entry.first);
          return [
            ResumeExperienceDraft(
              jobTitle: header.isEmpty ? '' : header.first,
              company: header.length > 1 ? header[1] : '',
              startDate: dates!.start!,
              endDate: dates.end,
              isCurrent: dates.isCurrent,
              bulletPoints: entry
                  .skip(1)
                  .where((line) => !_containsDate(line))
                  .toList(growable: false),
            ),
          ];
        })
        .toList(growable: false);
  }

  static List<ResumeProjectDraft> _parseProjects(List<String> lines) {
    return _entries(lines)
        .map((entry) {
          final text = entry.join(' ');
          final dates = _dateRange(text);
          final header = _headerParts(entry.first);
          final url = RegExp(
            r'https?://[^\s]+',
            caseSensitive: false,
          ).firstMatch(text)?.group(0);
          final technologyLine = entry.where(
            (line) => RegExp(
              r'^(?:technologies|tech stack|công nghệ)\s*:',
              caseSensitive: false,
            ).hasMatch(line),
          );
          final technologies = technologyLine
              .expand(
                (line) =>
                    line.split(':').skip(1).join(':').split(RegExp(r'[,;|]')),
              )
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          final details = entry
              .skip(1)
              .where(
                (line) =>
                    !_containsDate(line) &&
                    !line.contains('http://') &&
                    !line.contains('https://') &&
                    !technologyLine.contains(line),
              );
          return ResumeProjectDraft(
            name: header.isEmpty ? '' : header.first,
            role: header.length > 1 ? header[1] : '',
            description: details.join('\n'),
            technologies: technologies,
            sourceUrl: url,
            startDate: dates?.start,
            endDate: dates?.end,
          );
        })
        .where((item) => item.name.isNotEmpty)
        .toList(growable: false);
  }

  static List<ResumeCertificationDraft> _parseCertifications(
    List<String> lines,
  ) {
    return lines
        .map((line) {
          final header = _headerParts(line);
          final date = _dateRange(line)?.start;
          final url = RegExp(
            r'https?://[^\s]+',
            caseSensitive: false,
          ).firstMatch(line)?.group(0);
          final score = RegExp(
            r'\b(?:TOEIC|IELTS|TOEFL)?\s*(\d{1,3}(?:[.,]\d+)?)\b',
            caseSensitive: false,
          ).firstMatch(line)?.group(1);
          return ResumeCertificationDraft(
            name: header.isEmpty ? '' : header.first,
            issuer: header.length > 1 ? header[1] : '',
            score: score,
            issueDate: date,
            credentialUrl: url,
          );
        })
        .where((item) => item.name.isNotEmpty)
        .toList(growable: false);
  }

  static List<List<String>> _entries(List<String> lines) {
    final entries = <List<String>>[];
    var current = <String>[];
    var currentHasDate = false;
    for (final line in lines) {
      final lineHasDate = _containsDate(line);
      if (current.isNotEmpty && lineHasDate && currentHasDate) {
        entries.add(current);
        current = <String>[];
        currentHasDate = false;
      }
      current.add(line);
      currentHasDate = currentHasDate || lineHasDate;
    }
    if (current.isNotEmpty) entries.add(current);
    return entries;
  }

  static List<String> _headerParts(String value) {
    final clean = value
        .replaceAll(RegExp(r'https?://[^\s]+', caseSensitive: false), '')
        .replaceAll(_dateToken, '')
        .replaceAll(
          RegExp(
            r'\b(?:present|current|now|hiện tại|nay)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'[\s|\-–—]+$'), '')
        .trim();
    return clean
        .split(RegExp(r'\s+(?:\||–|—)\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  static final RegExp _dateToken = RegExp(
    r'(?<!\d)(?:(?:0?[1-9]|1[0-2])[/-])?(?:19|20)\d{2}(?!\d)',
  );

  static bool _containsDate(String value) => _dateToken.hasMatch(value);

  static bool _isGpaLine(String value) =>
      RegExp(r'(?:GPA|điểm trung bình)', caseSensitive: false).hasMatch(value);

  static _ResumeDateRange? _dateRange(String value) {
    final matches = _dateToken.allMatches(value).toList(growable: false);
    if (matches.isEmpty) return null;
    final isCurrent = RegExp(
      r'\b(?:present|current|now|hiện tại|nay)\b',
      caseSensitive: false,
    ).hasMatch(value);
    return _ResumeDateRange(
      start: _parseDate(matches.first.group(0)!),
      end: isCurrent || matches.length < 2
          ? null
          : _parseDate(matches[1].group(0)!),
      isCurrent: isCurrent,
    );
  }

  static DateTime _parseDate(String value) {
    final parts = value.split(RegExp(r'[/\\-]'));
    final year = int.parse(parts.last);
    final month = parts.length > 1 ? int.parse(parts.first) : 1;
    return DateTime.utc(year, month);
  }
}

final class _ResumeDateRange {
  const _ResumeDateRange({
    required this.start,
    required this.end,
    required this.isCurrent,
  });

  final DateTime? start;
  final DateTime? end;
  final bool isCurrent;
}
