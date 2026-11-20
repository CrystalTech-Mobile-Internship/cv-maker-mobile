import '../models/models.dart';
import '../../../../core/i18n/app_language.dart';

enum CvIssueSeverity { important, suggestion }

class CvQualityIssue {
  const CvQualityIssue({
    required this.section,
    required this.severity,
    required this.message,
    this.detail,
  });

  /// Section key from [CvModel.defaultSectionOrder] or 'personal'.
  final String section;
  final CvIssueSeverity severity;
  final String message;

  /// Offending text (shortened) to help the user locate the problem.
  final String? detail;
}

class CvQualityReport {
  const CvQualityReport(this.issues);

  final List<CvQualityIssue> issues;

  int get importantCount =>
      issues.where((i) => i.severity == CvIssueSeverity.important).length;

  /// 100 minus weighted penalties, floored at 0.
  int get score {
    var penalty = 0;
    for (final issue in issues) {
      penalty += issue.severity == CvIssueSeverity.important ? 10 : 4;
    }
    return (100 - penalty).clamp(0, 100);
  }
}

/// Offline writing-quality checks that complement the ATS completeness
/// checklist: style, clarity and consistency of what the user wrote.
abstract final class CvQualityChecker {
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final _digits = RegExp(r'\d');
  static final _firstPersonVi = RegExp(
    r'(^|[\s,.;:])(tôi|mình|em)(\s|$)',
    caseSensitive: false,
    unicode: true,
  );
  static final _firstPersonEn = RegExp(r'\b(I|me|my)\b');
  static final _placeholder = RegExp(r'\[[^\]]{1,20}\]');

  static CvQualityReport check(CvModel cv) {
    final issues = <CvQualityIssue>[];
    final en = cv.language == 'en';
    void add(
      String section,
      CvIssueSeverity severity,
      String message, [
      String? detail,
    ]) {
      issues.add(
        CvQualityIssue(
          section: section,
          severity: severity,
          message: message,
          detail: detail == null ? null : _short(detail),
        ),
      );
    }

    // Contact details
    final info = cv.personalInfo;
    if (info.fullName.trim().isEmpty) {
      add(
        'personal',
        CvIssueSeverity.important,
        tr('Thiếu họ tên.', 'Full name is missing.'),
      );
    }
    if (info.email.trim().isEmpty) {
      add(
        'personal',
        CvIssueSeverity.important,
        tr('Thiếu email liên hệ.', 'Contact email is missing.'),
      );
    } else if (!_email.hasMatch(info.email.trim())) {
      add(
        'personal',
        CvIssueSeverity.important,
        tr(
          'Email có vẻ chưa đúng định dạng.',
          'The email does not look right.',
        ),
        info.email,
      );
    }
    final phoneDigits = info.phone.replaceAll(RegExp(r'\D'), '');
    if (info.phone.trim().isNotEmpty &&
        (phoneDigits.length < 9 || phoneDigits.length > 13)) {
      add(
        'personal',
        CvIssueSeverity.suggestion,
        tr(
          'Số điện thoại có vẻ thiếu hoặc thừa chữ số.',
          'The phone number seems to have too few or too many digits.',
        ),
        info.phone,
      );
    }

    // Summary
    final summary = cv.summary.trim();
    if (summary.isEmpty) {
      add(
        'summary',
        CvIssueSeverity.important,
        tr(
          'Chưa có phần tóm tắt — nhà tuyển dụng đọc phần này đầu tiên.',
          'No summary yet — employers read it first.',
        ),
      );
    } else {
      if (summary.length < 120) {
        add(
          'summary',
          CvIssueSeverity.suggestion,
          tr(
            'Tóm tắt hơi ngắn; nên có 2–4 câu nêu vai trò, kỹ năng chính và mục tiêu.',
            'The summary is short; aim for 2–4 sentences on your role, key skills and goal.',
          ),
        );
      } else if (summary.length > 700) {
        add(
          'summary',
          CvIssueSeverity.suggestion,
          tr(
            'Tóm tắt dài hơn 700 ký tự; hãy rút gọn để dễ đọc.',
            'The summary is over 700 characters; shorten it so it is easy to read.',
          ),
        );
      }
      if (_usesFirstPerson(summary, en)) {
        add(
          'summary',
          CvIssueSeverity.suggestion,
          en
              ? 'Avoid first-person pronouns (I, me, my) in a CV summary.'
              : 'Nên tránh xưng "tôi/mình/em" trong CV; viết trực tiếp vào hành động.',
          summary,
        );
      }
    }

    // Experience bullets
    final allBullets = <String>[];
    for (final e in cv.experiences) {
      if (e.bulletPoints.isEmpty) {
        add(
          'experience',
          CvIssueSeverity.important,
          tr(
            'Kinh nghiệm chưa có mô tả công việc/thành tích.',
            'Experience has no description of work or results.',
          ),
          '${e.jobTitle} · ${e.company}',
        );
      }
      for (final bullet in e.bulletPoints) {
        allBullets.add(bullet);
        _checkBullet(bullet, 'experience', en, add);
      }
    }
    if (allBullets.length >= 3 && !allBullets.any(_digits.hasMatch)) {
      add(
        'experience',
        CvIssueSeverity.suggestion,
        tr(
          'Chưa có con số nào trong kinh nghiệm; hãy định lượng kết quả (%, số người dùng, thời gian…).',
          'No numbers in your experience; add measurable results (%, users, time…).',
        ),
      );
    }
    final repeated = _repeatedOpeners(allBullets);
    if (repeated != null) {
      add(
        'experience',
        CvIssueSeverity.suggestion,
        tr(
          'Nhiều gạch đầu dòng cùng mở đầu bằng "$repeated"; hãy đa dạng động từ hành động.',
          'Many bullet points start with "$repeated"; vary your action verbs.',
        ),
      );
    }

    // Projects
    for (final p in cv.projects) {
      if (p.description.trim().isEmpty) {
        add(
          'projects',
          CvIssueSeverity.suggestion,
          tr(
            'Dự án chưa có mô tả vai trò và kết quả.',
            'Project has no description of your role and results.',
          ),
          p.name,
        );
      }
      if (p.technologies.isEmpty) {
        add(
          'projects',
          CvIssueSeverity.suggestion,
          tr(
            'Dự án chưa liệt kê công nghệ sử dụng.',
            'Project does not list the technologies used.',
          ),
          p.name,
        );
      }
      if (_placeholder.hasMatch(p.description)) {
        add(
          'projects',
          CvIssueSeverity.important,
          tr(
            'Mô tả dự án còn chỗ [điền] chưa thay bằng thông tin thật.',
            'Project description still has [placeholders] to replace.',
          ),
          p.description,
        );
      }
    }

    // Skills
    final seen = <String>{};
    final duplicates = <String>{};
    for (final s in cv.skills) {
      final key = s.name.trim().toLowerCase();
      if (key.isEmpty) continue;
      if (!seen.add(key)) duplicates.add(s.name.trim());
    }
    if (duplicates.isNotEmpty) {
      add(
        'skills',
        CvIssueSeverity.suggestion,
        tr(
          'Kỹ năng bị trùng: ${duplicates.join(', ')}.',
          'Duplicate skills: ${duplicates.join(', ')}.',
        ),
      );
    }
    if (cv.skills.length > 20) {
      add(
        'skills',
        CvIssueSeverity.suggestion,
        tr(
          'Có ${cv.skills.length} kỹ năng; nên giữ 8–15 kỹ năng liên quan nhất.',
          '${cv.skills.length} skills; keep the 8–15 most relevant.',
        ),
      );
    } else if (cv.skills.isEmpty) {
      add(
        'skills',
        CvIssueSeverity.important,
        tr('Chưa có kỹ năng nào.', 'No skills yet.'),
      );
    }

    // Education
    for (final e in cv.educations) {
      if (e.isCurrent && e.endDate != null) {
        add(
          'education',
          CvIssueSeverity.suggestion,
          tr(
            'Mục học vấn vừa đánh dấu "đang học" vừa có ngày kết thúc.',
            'An education entry is marked "current" but also has an end date.',
          ),
          e.institution,
        );
      }
    }

    issues.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return CvQualityReport(List.unmodifiable(issues));
  }

  static void _checkBullet(
    String bullet,
    String section,
    bool en,
    void Function(String, CvIssueSeverity, String, [String?]) add,
  ) {
    final text = bullet.trim();
    if (text.length > 220) {
      add(
        section,
        CvIssueSeverity.suggestion,
        tr(
          'Gạch đầu dòng quá dài (>220 ký tự); nên tách hoặc rút gọn.',
          'Bullet point is too long (>220 characters); split or shorten it.',
        ),
        text,
      );
    } else if (text.length < 20) {
      add(
        section,
        CvIssueSeverity.suggestion,
        tr(
          'Gạch đầu dòng quá ngắn; hãy nêu rõ việc đã làm và kết quả.',
          'Bullet point is too short; say what you did and the result.',
        ),
        text,
      );
    }
    if (_placeholder.hasMatch(text)) {
      add(
        section,
        CvIssueSeverity.important,
        tr(
          'Còn chỗ [điền] chưa thay bằng số liệu thật.',
          'There are [placeholders] still to replace with real numbers.',
        ),
        text,
      );
    }
    if (_usesFirstPerson(text, en)) {
      add(
        section,
        CvIssueSeverity.suggestion,
        en
            ? 'Start bullets with an action verb instead of "I".'
            : 'Bắt đầu bằng động từ hành động thay vì "tôi/mình".',
        text,
      );
    }
    if (text.isNotEmpty && text[0] != text[0].toUpperCase()) {
      add(
        section,
        CvIssueSeverity.suggestion,
        tr(
          'Nên viết hoa chữ cái đầu gạch đầu dòng.',
          'Start bullet points with a capital letter.',
        ),
        text,
      );
    }
  }

  static bool _usesFirstPerson(String text, bool en) =>
      en ? _firstPersonEn.hasMatch(text) : _firstPersonVi.hasMatch(text);

  static String? _repeatedOpeners(List<String> bullets) {
    final counts = <String, int>{};
    for (final bullet in bullets) {
      final words = bullet.trim().split(RegExp(r'\s+'));
      if (words.isEmpty || words.first.isEmpty) continue;
      final opener = words.first.toLowerCase();
      counts[opener] = (counts[opener] ?? 0) + 1;
    }
    for (final entry in counts.entries) {
      if (entry.value >= 3) return entry.key;
    }
    return null;
  }

  static String _short(String text) =>
      text.length > 90 ? '${text.substring(0, 87)}...' : text;
}
