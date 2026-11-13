import '../../../ai_tools/domain/services/jd_keyword_extractor.dart';
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

    final corpus = buildCorpus(cv);

    final matched = <String>[];
    final missing = <String>[];

    for (final kw in targetKeywords) {
      final cleanKw = kw.trim().toLowerCase();
      if (cleanKw.isEmpty) continue;

      if (corpus.contains(cleanKw) ||
          JdKeywordExtractor.corpusMentions(corpus, kw)) {
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

  /// Scores [cv] against a free-text job description by extracting known
  /// keywords offline first.
  static JdMatchReport evaluateJobDescription({
    required CvModel cv,
    required String jobDescription,
  }) {
    return evaluate(
      cv: cv,
      targetKeywords: JdKeywordExtractor.extract(jobDescription),
    );
  }

  /// Lowercase text of every CV field that an ATS would index.
  static String buildCorpus(CvModel cv) {
    final buffer = StringBuffer()
      ..writeln(cv.title)
      ..writeln(cv.personalInfo.targetRole)
      ..writeln(cv.summary);
    for (final skill in cv.skills) {
      buffer.writeln(skill.name);
    }
    for (final exp in cv.experiences) {
      buffer.writeln(
        '${exp.jobTitle} ${exp.company} ${exp.bulletPoints.join(' ')}',
      );
    }
    for (final project in cv.projects) {
      buffer.writeln(
        '${project.name} ${project.role} ${project.description} '
        '${project.technologies.join(' ')}',
      );
    }
    for (final edu in cv.educations) {
      buffer.writeln(
        '${edu.institution} ${edu.degree} ${edu.fieldOfStudy} '
        '${edu.achievements.join(' ')}',
      );
    }
    for (final cert in cv.certifications) {
      buffer.writeln('${cert.name} ${cert.issuer} ${cert.score ?? ''}');
    }
    return buffer.toString().toLowerCase();
  }
}
