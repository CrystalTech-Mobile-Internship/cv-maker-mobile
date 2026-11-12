import '../../../cv_editor/domain/models/cv_model.dart';

/// Compact plain-text rendering of a CV for AI prompts. Contact details
/// (email, phone, address, links) are deliberately left out: the AI does not
/// need them to write content.
String cvPlainText(CvModel cv, {int maxLength = 6000}) {
  String period(DateTime? start, DateTime? end, bool current) {
    String fmt(DateTime? d) =>
        d == null ? '' : '${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${fmt(start)} - ${current ? 'nay' : fmt(end)}';
  }

  final buffer = StringBuffer()
    ..writeln('Họ tên: ${cv.personalInfo.fullName}')
    ..writeln('Vị trí mục tiêu: ${cv.personalInfo.targetRole}');
  if (cv.summary.trim().isNotEmpty) {
    buffer.writeln('Tóm tắt: ${cv.summary.trim()}');
  }
  if (cv.skills.isNotEmpty) {
    buffer.writeln('Kỹ năng: ${cv.skills.map((s) => s.name).join(', ')}');
  }
  for (final e in cv.experiences) {
    buffer.writeln(
      'Kinh nghiệm: ${e.jobTitle} tại ${e.company} '
      '(${period(e.startDate, e.endDate, e.isCurrent)})',
    );
    for (final bullet in e.bulletPoints) {
      buffer.writeln('  - $bullet');
    }
  }
  for (final p in cv.projects) {
    buffer.writeln(
      'Dự án: ${p.name} (${p.role}) ${p.description} '
      '[${p.technologies.join(', ')}]',
    );
  }
  for (final e in cv.educations) {
    buffer.writeln(
      'Học vấn: ${e.degree} ${e.fieldOfStudy} - ${e.institution}'
      '${e.gpa == null ? '' : ', GPA ${e.gpa}'}',
    );
  }
  for (final c in cv.certifications) {
    buffer.writeln('Chứng chỉ: ${c.name} ${c.score ?? ''}'.trim());
  }
  final text = buffer.toString();
  return text.length > maxLength ? text.substring(0, maxLength) : text;
}
