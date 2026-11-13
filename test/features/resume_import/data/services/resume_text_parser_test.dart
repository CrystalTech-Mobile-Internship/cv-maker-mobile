import 'package:cv_maker_mobile/features/resume_import/data/services/resume_text_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ResumeTextParser();

  test('extracts identity, contact, summary and skills from Vietnamese CV', () {
    final draft = parser.parse(
      sourceName: 'hoa.docx',
      text: '''
TRẦN VĂN HÒA
Flutter Developer
hoa@example.com | 0912 345 678
MỤC TIÊU NGHỀ NGHIỆP
Mong muốn phát triển ứng dụng mobile ổn định và dễ sử dụng.
KỸ NĂNG
Flutter, Dart, Git, Supabase
HỌC VẤN
Đại học Công nghiệp TP.HCM — Kỹ sư — Công nghệ thông tin | 09/2023 - 06/2027
GPA: 2.9/4.0
KINH NGHIỆM
Flutter Intern — Công ty XYZ | 06/2026 - 09/2026
Xây dựng giao diện Flutter và viết kiểm thử widget.
DỰ ÁN
Smart CV Maker — Mobile Developer | 01/2026 - Hiện tại
Công nghệ: Flutter, Drift, Supabase
https://github.com/example/smart-cv
Phát triển luồng tạo và xuất CV offline.
CHỨNG CHỈ
TOEIC 700 — IIG Việt Nam | 2026
''',
    );

    expect(draft.fullName, 'TRẦN VĂN HÒA');
    expect(draft.targetRole, 'Flutter Developer');
    expect(draft.email, 'hoa@example.com');
    expect(draft.phone, '0912 345 678');
    expect(draft.summary, contains('ứng dụng mobile'));
    expect(draft.skills, containsAll(['Flutter', 'Dart', 'Supabase']));
    expect(draft.educations, hasLength(1));
    expect(draft.educations.single.institution, contains('Đại học'));
    expect(draft.educations.single.gpa, '2.9/4.0');
    expect(draft.experiences.single.company, 'Công ty XYZ');
    expect(draft.experiences.single.bulletPoints, isNotEmpty);
    expect(draft.projects.single.technologies, contains('Drift'));
    expect(draft.projects.single.sourceUrl, contains('github.com'));
    expect(draft.certifications.single.score, '700');

    final cv = draft.toCv(
      id: 'imported-cv',
      title: 'CV Flutter',
      templateId: 'harvard_ats',
      primaryColor: '#1E293B',
      language: 'vi',
      now: DateTime.utc(2026, 10, 30),
    );
    expect(cv.educations, hasLength(1));
    expect(cv.experiences, hasLength(1));
    expect(cv.projects, hasLength(1));
    expect(cv.certifications, hasLength(1));
  });

  test('warns instead of inventing data for a nearly empty scan', () {
    final draft = parser.parse(sourceName: 'scan.pdf', text: 'CV');

    expect(draft.email, isEmpty);
    expect(draft.skills, isEmpty);
    expect(draft.warnings.first, contains('rất ít chữ'));
  });

  test('reads an English CV whose introduction has no heading', () {
    const text = '''
LE MINH KHOA
Da Nang, Vietnam  •  minhkhoa.dev@example.com  •  +84 -900000006  •  github.com/example-khoa

Final-year Software Engineering student focused on backend development.
Experienced in building web and mobile apps with Java and React. Seeking a
Backend or Full-stack opportunity to build reliable products.
EDUCATION
Example University of Technology — Software Engineering      Sep 2022 – Present
GPA: 3.2 / 4.0
SKILLS
Languages: Java, JavaScript, TypeScript
Backend: Spring Boot, RESTful API, Redis
Frontend: ReactJS, Flutter
Databases: MySQL, PostgreSQL
PROJECT
TravelHub – Tour Booking Platform Apr 2026 – Jun 2026
Spring Boot, PostgreSQL, ReactJS | Full Stack Developer (Team of 5)
• Built tour and booking services.
StudyNote – Mobile Learning App Sep 2025 – Nov 2025
React Native, TypeScript | Mobile Developer (Team of 2)
• Built course browsing and lesson screens.
''';
    final draft = parser.parse(sourceName: 'cv.pdf', text: text);

    expect(draft.fullName, 'LE MINH KHOA');
    expect(draft.address, 'Da Nang, Vietnam');
    expect(
      draft.summary,
      startsWith('Final-year Software Engineering student'),
    );
    expect(draft.targetRole, 'Backend or Full-stack');
    expect(
      draft.skills,
      containsAll(['Java', 'Spring Boot', 'ReactJS', 'PostgreSQL']),
    );
    expect(draft.skills.any((skill) => skill.contains(':')), isFalse);
    expect(draft.projects.map((p) => p.name), [
      'TravelHub – Tour Booking Platform',
      'StudyNote – Mobile Learning App',
    ]);
    expect(draft.projects.first.startDate, DateTime.utc(2026, 4));
    expect(draft.educations.single.startDate, DateTime.utc(2022, 9));
    expect(draft.educations.single.isCurrent, isTrue);
  });

  test('never uses a long sentence as the target role', () {
    final draft = parser.parse(
      sourceName: 'cv.pdf',
      text:
          'TRAN AN\n'
          'Student with a strong interest in building products that help people learn.\n'
          'an.tran@example.com\n',
    );
    expect(draft.targetRole, isEmpty);
  });
}
