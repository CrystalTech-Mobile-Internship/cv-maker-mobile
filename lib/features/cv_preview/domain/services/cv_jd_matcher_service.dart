import '../../../cv_editor/domain/models/cv_model.dart';

class JdMatchReport {
  const JdMatchReport({
    required this.score,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.totalKeywords,
  });

  final int score;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final int totalKeywords;
}

class CvJdPreset {
  const CvJdPreset({
    required this.id,
    required this.titleVi,
    required this.titleEn,
    required this.keywords,
  });

  final String id;
  final String titleVi;
  final String titleEn;
  final List<String> keywords;

  String title(String language) => language == 'en' ? titleEn : titleVi;
}

abstract final class CvJdMatcherService {
  static const List<CvJdPreset> presets = [
    CvJdPreset(
      id: 'flutter_mobile',
      titleVi: 'Lập trình viên Flutter / Mobile',
      titleEn: 'Flutter / Mobile Engineer',
      keywords: [
        'Flutter',
        'Dart',
        'Riverpod',
        'BLoC',
        'SQLite',
        'Drift',
        'RESTful API',
        'Clean Architecture',
        'Git',
        'CI/CD',
        'Firebase',
        'Unit Test',
      ],
    ),
    CvJdPreset(
      id: 'frontend_web',
      titleVi: 'Lập trình viên Frontend Web',
      titleEn: 'Frontend Web Developer',
      keywords: [
        'React',
        'TypeScript',
        'Next.js',
        'JavaScript',
        'Tailwind CSS',
        'Redux',
        'HTML5',
        'CSS3',
        'REST API',
        'Responsive Design',
      ],
    ),
    CvJdPreset(
      id: 'backend_api',
      titleVi: 'Kỹ sư Backend & Cloud API',
      titleEn: 'Backend & Cloud Engineer',
      keywords: [
        'Node.js',
        'Python',
        'Java',
        'Spring Boot',
        'PostgreSQL',
        'Docker',
        'Redis',
        'Microservices',
        'RESTful API',
        'SQL',
      ],
    ),
    CvJdPreset(
      id: 'fresher_junior',
      titleVi: 'Sinh viên IT / Fresher mới ra trường',
      titleEn: 'Fresher / Junior IT Developer',
      keywords: [
        'OOP',
        'Data Structures',
        'Git',
        'SQL',
        'Problem Solving',
        'English',
        'Teamwork',
        'Self-learning',
      ],
    ),
  ];

  static JdMatchReport evaluate({
    required CvModel cv,
    required List<String> targetKeywords,
  }) {
    if (targetKeywords.isEmpty) {
      return const JdMatchReport(
        score: 0,
        matchedKeywords: [],
        missingKeywords: [],
        totalKeywords: 0,
      );
    }

    final cvCorpusBuffer = StringBuffer();
    cvCorpusBuffer.writeln(cv.title);
    cvCorpusBuffer.writeln(cv.personalInfo.targetRole);
    cvCorpusBuffer.writeln(cv.summary);

    for (final s in cv.skills) {
      cvCorpusBuffer.writeln(s.name);
    }
    for (final exp in cv.experiences) {
      cvCorpusBuffer.writeln('${exp.jobTitle} ${exp.company} ${exp.bulletPoints.join(' ')}');
    }
    for (final proj in cv.projects) {
      cvCorpusBuffer.writeln('${proj.name} ${proj.role} ${proj.description} ${proj.technologies.join(' ')}');
    }
    for (final edu in cv.educations) {
      cvCorpusBuffer.writeln('${edu.institution} ${edu.degree} ${edu.fieldOfStudy}');
    }

    final corpus = cvCorpusBuffer.toString().toLowerCase();

    final matched = <String>[];
    final missing = <String>[];

    for (final kw in targetKeywords) {
      final cleanKw = kw.trim().toLowerCase();
      if (cleanKw.isEmpty) continue;

      if (corpus.contains(cleanKw)) {
        matched.add(kw);
      } else {
        missing.add(kw);
      }
    }

    final total = matched.length + missing.length;
    final score = total > 0 ? ((matched.length / total) * 100).round() : 0;

    return JdMatchReport(
      score: score,
      matchedKeywords: List.unmodifiable(matched),
      missingKeywords: List.unmodifiable(missing),
      totalKeywords: total,
    );
  }
}
