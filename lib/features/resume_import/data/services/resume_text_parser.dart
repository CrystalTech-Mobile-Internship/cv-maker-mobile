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
      'project',
      'personal projects',
      'dự án',
      'certifications',
      'certificates',
      'certificate',
      'chứng chỉ',
      'technical skills',
      'activities',
      'hoạt động',
      'awards',
      'giải thưởng',
    };
    final firstHeading = lines.indexWhere(
      (line) => headings.contains(_headingKey(line)),
    );
    final intro = firstHeading < 0
        ? lines.take(8).toList(growable: false)
        : lines.take(firstHeading).toList(growable: false);
    final contactLine = intro.firstWhere(
      (line) =>
          line.contains('@') || (phone.isNotEmpty && line.contains(phone)),
      orElse: () => '',
    );
    final introBody = intro
        .where((line) => line != contactLine)
        .where((line) => !headings.contains(_headingKey(line)))
        .toList(growable: false);
    // Name, then an optional short title line ("Backend Developer").
    final identityLines = <String>[
      if (introBody.isNotEmpty) introBody.first,
      if (introBody.length > 1 && _looksLikeTitle(introBody[1])) introBody[1],
    ];

    final headedSummary = _section(
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
    // Many CVs put a short introduction under the contact line without a
    // "Summary" heading.
    final introSummary = intro
        .where((line) => line != contactLine && !identityLines.contains(line))
        .join(' ');
    final summary = headedSummary.isNotEmpty
        ? headedSummary
        : (introSummary.length >= 60 ? introSummary : '');
    final skillLines = _section(
      lines,
      starts: const {'skills', 'kỹ năng', 'technical skills'},
      allHeadings: headings,
    );
    final skills = skillLines
        // "Backend: Spring Boot, Redis" -> "Spring Boot, Redis"
        .map((line) => line.replaceFirst(RegExp(r'^[^:,]{2,30}:\s*'), ''))
        .expand((line) => line.split(RegExp(r'[,;|•·]')))
        .map((skill) => skill.trim())
        .where((skill) => skill.length >= 2 && skill.length <= 48)
        .toSet()
        .take(40)
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
      starts: const {'projects', 'project', 'personal projects', 'dự án'},
      allHeadings: headings,
    );
    final certificationLines = _section(
      lines,
      starts: const {
        'certifications',
        'certificates',
        'certificate',
        'chứng chỉ',
      },
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
      targetRole: _targetRole(identityLines, summary),
      email: email,
      phone: phone,
      address: _address(contactLine, email: email),
      summary: summary,
      skills: skills,
      educations: educations,
      experiences: experiences,
      projects: projects,
      certifications: certifications,
      warnings: warnings,
    );
  }

  /// A short title line under the name, or the role named in the summary
  /// ("Seeking a Backend Developer role", "ứng tuyển vị trí ...").
  static String _targetRole(List<String> identityLines, String summary) {
    if (identityLines.length > 1) return identityLines[1];
    final english = RegExp(
      r'(?:seeking|looking for)\s+(?:an?\s+)?(.{3,70}?)\s+(?:opportunit(?:y|ies)|position|role|internship)',
      caseSensitive: false,
    ).firstMatch(summary);
    if (english != null) return _capitalize(english.group(1)!.trim());
    final vietnamese = RegExp(
      r'vị trí\s+([^,.;]{3,60})',
      caseSensitive: false,
    ).firstMatch(summary);
    if (vietnamese != null) return _capitalize(vietnamese.group(1)!.trim());
    return '';
  }

  /// The part of the contact line that is not an email, phone or link.
  static String _address(String contactLine, {required String email}) {
    if (contactLine.isEmpty) return '';
    for (final part in contactLine.split(RegExp(r'\s*[•·|]\s*'))) {
      final value = part.trim();
      if (value.isEmpty || value.contains('@')) continue;
      if (email.isNotEmpty && value.contains(email)) continue;
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 6) continue;
      if (RegExp(
        r'https?://|www\.|github\.com|linkedin\.com',
        caseSensitive: false,
      ).hasMatch(value)) {
        continue;
      }
      if (RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(value)) return value;
    }
    return '';
  }

  /// "SmartEnglish AI - Learning App Aug 2026 - Present | In Development"
  /// -> "SmartEnglish AI - Learning App".
  static String _titleBeforeBar(String line) {
    final withoutDates = line
        .replaceAll(_dateToken, '')
        .replaceAll(
          RegExp(
            r'\b(?:present|current|now|hiện tại|nay)\b',
            caseSensitive: false,
          ),
          '',
        );
    return withoutDates
        .split('|')
        .first
        .replaceAll(RegExp(r'(?:\s*[-–—]\s*)+$'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  static bool _looksLikeTitle(String value) =>
      value.length <= 60 &&
      value.split(RegExp(r'\s+')).length <= 8 &&
      !value.endsWith('.');

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

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
    return result.take(80).toList(growable: false);
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
          final url =
              RegExp(
                r'https?://[^\s]+',
                caseSensitive: false,
              ).firstMatch(text)?.group(0) ??
              RegExp(r'\bgithub\.com/[^\s,]+', caseSensitive: false)
                  .firstMatch(text)
                  ?.group(0)
                  ?.replaceFirst(RegExp(r'^'), 'https://');
          final labelledTech = entry.where(
            (line) => RegExp(
              r'^(?:technologies|tech stack|công nghệ)\s*:',
              caseSensitive: false,
            ).hasMatch(line),
          );
          // "Spring Boot, PostgreSQL | Full Stack Developer (Team of 5)",
          // possibly wrapped over several lines that end with a comma.
          final body = entry.skip(1).toList(growable: false);
          final infoIndex = body.indexWhere(
            (line) => line.contains('|') && line.contains(','),
          );
          var infoStart = infoIndex;
          while (infoStart > 0 && body[infoStart - 1].trim().endsWith(',')) {
            infoStart--;
          }
          final infoLines = infoIndex < 0
              ? const <String>[]
              : body.sublist(infoStart, infoIndex + 1);
          final infoLine = infoLines.isEmpty ? null : infoLines.join(' ');
          final technologies =
              <String>[
                    ...labelledTech.expand(
                      (line) => line
                          .split(':')
                          .skip(1)
                          .join(':')
                          .split(RegExp(r'[,;|]')),
                    ),
                    if (infoLine != null)
                      ...infoLine.split('|').first.split(','),
                  ]
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toList();
          final role = infoLine != null
              ? infoLine.split('|').last.trim()
              : (header.length > 1 && entry.length > 1 ? header[1] : '');
          // Keep "Name – Subtitle" together when the role comes from a
          // separate line.
          final name = infoLine != null || entry.length == 1
              ? _titleBeforeBar(entry.first)
              : (header.isEmpty ? '' : header.first);
          final details = entry
              .skip(1)
              .where(
                (line) =>
                    !_containsDate(line) &&
                    !infoLines.contains(line) &&
                    !labelledTech.contains(line) &&
                    !RegExp(
                      r'https?://|github\.com/',
                      caseSensitive: false,
                    ).hasMatch(line),
              );
          return ResumeProjectDraft(
            name: name,
            role: role,
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

  static const _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  /// "2024", "03/2024", "3-2024" or "Aug 2024".
  static final RegExp _dateToken = RegExp(
    r'(?:\b(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s+|(?<!\d)(?:0?[1-9]|1[0-2])[/-])?(?<!\d)(?:19|20)\d{2}(?!\d)',
    caseSensitive: false,
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
    final year = int.parse(
      RegExp(r'(?:19|20)\d{2}').firstMatch(value)!.group(0)!,
    );
    final named = RegExp(r'^[a-z]{3}', caseSensitive: false).firstMatch(value);
    if (named != null) {
      return DateTime.utc(year, _months[named.group(0)!.toLowerCase()] ?? 1);
    }
    final parts = value.split(RegExp(r'[/\\-]'));
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
