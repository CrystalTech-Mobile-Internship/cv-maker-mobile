import '../models/skill_model.dart';

/// Predefined category group for browsing skills.
class SkillDomainGroup {
  const SkillDomainGroup({
    required this.id,
    required this.titleVi,
    required this.titleEn,
    required this.iconName,
    required this.skills,
  });

  final String id;
  final String titleVi;
  final String titleEn;
  final String iconName;
  final List<SkillRecommendation> skills;

  String title(String language) => language == 'en' ? titleEn : titleVi;
}

class SkillRecommendation {
  const SkillRecommendation({
    required this.name,
    this.category = SkillCategory.hard,
    this.defaultProficiency = 80,
  });

  final String name;
  final SkillCategory category;
  final int defaultProficiency;
}

/// Offline catalog of popular technical and soft skills categorized by job domain.
abstract final class CvSkillCatalogService {
  static const List<SkillDomainGroup> groups = [
    SkillDomainGroup(
      id: 'mobile',
      titleVi: 'Lập trình Di động (Mobile)',
      titleEn: 'Mobile Development',
      iconName: 'phone_android',
      skills: [
        SkillRecommendation(name: 'Flutter & Dart'),
        SkillRecommendation(name: 'State Management (Riverpod / BLoC)'),
        SkillRecommendation(name: 'SQLite / Drift Database'),
        SkillRecommendation(name: 'RESTful API & JSON'),
        SkillRecommendation(name: 'Clean Architecture'),
        SkillRecommendation(name: 'Firebase & Push Notification'),
        SkillRecommendation(name: 'Kotlin / Android Native'),
        SkillRecommendation(name: 'Swift / iOS Native'),
        SkillRecommendation(name: 'Git & GitHub Workflow'),
        SkillRecommendation(name: 'CI/CD & App Deployment'),
      ],
    ),
    SkillDomainGroup(
      id: 'web_frontend',
      titleVi: 'Lập trình Web / Frontend',
      titleEn: 'Web & Frontend',
      iconName: 'web',
      skills: [
        SkillRecommendation(name: 'React.js / Next.js'),
        SkillRecommendation(name: 'TypeScript'),
        SkillRecommendation(name: 'JavaScript (ES6+)'),
        SkillRecommendation(name: 'HTML5 & CSS3 / SCSS'),
        SkillRecommendation(name: 'Tailwind CSS'),
        SkillRecommendation(name: 'Redux Toolkit / Zustand'),
        SkillRecommendation(name: 'RESTful & GraphQL APIs'),
        SkillRecommendation(name: 'Responsive Web Design'),
        SkillRecommendation(name: 'Vite / Webpack'),
        SkillRecommendation(name: 'Unit Testing (Jest / Vitest)'),
      ],
    ),
    SkillDomainGroup(
      id: 'backend',
      titleVi: 'Hệ thống Backend & API',
      titleEn: 'Backend & Cloud API',
      iconName: 'dns',
      skills: [
        SkillRecommendation(name: 'Node.js & Express / NestJS'),
        SkillRecommendation(name: 'Python (Django / FastAPI)'),
        SkillRecommendation(name: 'Java (Spring Boot)'),
        SkillRecommendation(name: 'Golang'),
        SkillRecommendation(name: 'PostgreSQL & MySQL'),
        SkillRecommendation(name: 'Redis In-Memory Caching'),
        SkillRecommendation(name: 'Docker & Containerization'),
        SkillRecommendation(name: 'Microservices Architecture'),
        SkillRecommendation(name: 'JWT & OAuth2 Authentication'),
        SkillRecommendation(name: 'RESTful & gRPC APIs'),
      ],
    ),
    SkillDomainGroup(
      id: 'data_ai',
      titleVi: 'Dữ liệu & Trí tuệ nhân tạo (AI)',
      titleEn: 'Data Science & AI',
      iconName: 'analytics',
      skills: [
        SkillRecommendation(name: 'Python Data Stack (Pandas, NumPy)'),
        SkillRecommendation(name: 'SQL (Query Optimization)'),
        SkillRecommendation(name: 'Machine Learning (Scikit-Learn)'),
        SkillRecommendation(name: 'Deep Learning (PyTorch / TensorFlow)'),
        SkillRecommendation(name: 'Data Visualization (PowerBI / Tableau)'),
        SkillRecommendation(name: 'LLM & Prompt Engineering'),
        SkillRecommendation(name: 'Big Data (Apache Spark)'),
        SkillRecommendation(name: 'Statistical Data Analysis'),
      ],
    ),
    SkillDomainGroup(
      id: 'soft_skills',
      titleVi: 'Kỹ năng mềm & Hội nhập',
      titleEn: 'Soft Skills & Workplace',
      iconName: 'people',
      skills: [
        SkillRecommendation(
          name: 'Làm việc nhóm & Phối hợp (Teamwork)',
          category: SkillCategory.soft,
        ),
        SkillRecommendation(
          name: 'Quản lý thời gian & Tiến độ',
          category: SkillCategory.soft,
        ),
        SkillRecommendation(
          name: 'Tư duy giải quyết vấn đề (Problem Solving)',
          category: SkillCategory.soft,
        ),
        SkillRecommendation(
          name: 'Giao tiếp & Thuyết trình chuyên nghiệp',
          category: SkillCategory.soft,
        ),
        SkillRecommendation(
          name: 'Tư duy phản biện & Độc lập',
          category: SkillCategory.soft,
        ),
        SkillRecommendation(
          name: 'Thích ứng linh hoạt & Học hỏi nhanh',
          category: SkillCategory.soft,
        ),
        SkillRecommendation(
          name: 'Tiếng Anh giao tiếp & Đọc hiểu kỹ thuật',
          category: SkillCategory.soft,
        ),
      ],
    ),
  ];

  static List<SkillRecommendation> findSuggestionsByDomain(String domainId) {
    return groups
        .firstWhere((g) => g.id == domainId, orElse: () => groups.first)
        .skills;
  }
}
