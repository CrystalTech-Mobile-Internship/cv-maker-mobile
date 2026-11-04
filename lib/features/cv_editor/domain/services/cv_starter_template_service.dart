import '../models/certification_model.dart';
import '../models/education_model.dart';
import '../models/experience_model.dart';
import '../models/project_model.dart';
import '../models/skill_model.dart';

class StarterSummaryOption {
  const StarterSummaryOption({
    required this.id,
    required this.titleVi,
    required this.titleEn,
    required this.contentVi,
    required this.contentEn,
  });

  final String id;
  final String titleVi;
  final String titleEn;
  final String contentVi;
  final String contentEn;

  String title(String lang) => lang == 'en' ? titleEn : titleVi;
  String content(String lang) => lang == 'en' ? contentEn : contentVi;
}

class CvStarterTemplateService {
  const CvStarterTemplateService();

  static const List<StarterSummaryOption> summaryOptions = [
    StarterSummaryOption(
      id: 'fresher_it',
      titleVi: 'Sinh viên CNTT / Fresher tốt nghiệp',
      titleEn: 'IT Fresher / New Graduate',
      contentVi:
          'Cử nhân Công nghệ Thông tin nhiệt huyết với nền tảng vững chắc về lập trình phần mềm, tư duy giải thuật và Clean Architecture. Đã hoàn thành các dự án thực tế về ứng dụng di động Flutter và Supabase backend. Mong muốn gia nhập đội ngũ để đóng góp giá trị và không ngừng trau dồi chuyên môn.',
      contentEn:
          'Enthusiastic Computer Science graduate with strong foundations in software engineering, data structures, and Clean Architecture. Experienced in building production-ready mobile apps with Flutter and Supabase. Seeking a Fresher/Junior position to contribute to impactful software products.',
    ),
    StarterSummaryOption(
      id: 'mobile_dev',
      titleVi: 'Lập trình viên Mobile (Flutter / Android)',
      titleEn: 'Mobile Developer (Flutter / Android)',
      contentVi:
          'Kỹ sư phần mềm chuyên về phát triển ứng dụng di động đa nền tảng Flutter. Có kinh nghiệm sâu sắc về quản lý trạng thái (Riverpod), cơ sở dữ liệu ngoại tuyến (SQLite/Drift), tích hợp REST API và xuất bản ứng dụng. Thế mạnh về tối ưu giao diện mượt mà và trải nghiệm người dùng.',
      contentEn:
          'Software Engineer specializing in cross-platform mobile development with Flutter. Deep expertise in state management (Riverpod), offline-first SQLite persistence, REST APIs, and responsive design. Passionate about delivering smooth UI performance and robust user experiences.',
    ),
    StarterSummaryOption(
      id: 'backend_dev',
      titleVi: 'Lập trình viên Backend / Full-stack',
      titleEn: 'Backend / Full-stack Developer',
      contentVi:
          'Lập trình viên định hướng Backend với năng lực thiết kế hệ thống phân tán, cơ sở dữ liệu PostgreSQL/MySQL và RESTful API bảo mật. Có kinh nghiệm xây dựng ứng dụng toàn diện từ giao diện người dùng đến dịch vụ đám mây, tối ưu truy vấn và viết kiểm thử tự động.',
      contentEn:
          'Backend-focused Software Developer with capabilities in relational database design (PostgreSQL/MySQL), scalable RESTful APIs, and cloud services. Experienced in end-to-end full-stack architectures, query optimization, and rigorous automated testing.',
    ),
    StarterSummaryOption(
      id: 'business_marketing',
      titleVi: 'Chuyên viên Kinh doanh / Marketing',
      titleEn: 'Business & Marketing Specialist',
      contentVi:
          'Chuyên viên phát triển kinh doanh năng động với kỹ năng giao tiếp, đàm phán và phân tích thị trường xuất sắc. Có kinh nghiệm quản lý quan hệ khách hàng, tối ưu kênh bán hàng và xây dựng chiến lược truyền thông nhằm gia tăng doanh thu và độ nhận diện thương hiệu.',
      contentEn:
          'Dynamic business professional with strong skills in market analysis, customer relationship management, and sales growth. Proven track record in executing targeted marketing campaigns, optimizing conversion funnels, and building long-term partnerships.',
    ),
  ];

  static List<ExperienceModel> getStarterExperiences(String language) {
    final isEn = language == 'en';
    final now = DateTime.now();

    return [
      ExperienceModel(
        id: 'starter-exp-1',
        company: isEn ? 'Tech Innovations Corp' : 'Công ty Công nghệ Alpha',
        jobTitle: isEn ? 'Mobile Developer Intern' : 'Thực tập sinh Lập trình Di động',
        location: isEn ? 'Ho Chi Minh City' : 'TP. Hồ Chí Minh',
        startDate: DateTime.utc(now.year - 1, 6, 1),
        endDate: DateTime.utc(now.year, 2, 1),
        isCurrent: false,
        bulletPoints: isEn
            ? [
                'Developed key user onboarding and checkout modules using Flutter and Riverpod.',
                'Integrated Supabase Auth and PostgreSQL, speeding up user login response by 35%.',
                'Wrote unit and widget tests achieving over 85% test coverage for core features.',
              ]
            : [
                'Phát triển các module xác thực người dùng và giỏ hàng bằng Flutter và Riverpod.',
                'Tích hợp Supabase Auth và cơ sở dữ liệu PostgreSQL, tối ưu thời gian phản hồi API.',
                'Viết kiểm thử tự động (Unit & Widget Test) đảm bảo độ ổn định và không phát sinh lỗi.',
              ],
      ),
    ];
  }

  static List<ProjectModel> getStarterProjects(String language) {
    final isEn = language == 'en';
    final now = DateTime.now();

    return [
      ProjectModel(
        id: 'starter-proj-1',
        name: isEn ? 'Smart CV Maker Mobile' : 'Smart CV Maker Mobile',
        role: isEn ? 'Core Developer' : 'Lập trình viên chính',
        technologies: ['Flutter', 'Riverpod', 'Drift SQLite', 'Supabase'],
        sourceUrl: 'https://github.com/example/cv-maker',
        demoUrl: 'https://smartcv.example.com',
        startDate: DateTime.utc(now.year, 1, 1),
        endDate: DateTime.utc(now.year, 4, 1),
        description: isEn
            ? 'Cross-platform resume builder with true A4 rendering, vector PDF export, and offline SQLite sync.'
            : 'Ứng dụng tạo CV chuyên nghiệp đa nền tảng, xem trước chuẩn khổ A4, xuất file PDF vector sắc nét và đồng bộ SQLite ngoại tuyến.',
      ),
    ];
  }

  static List<SkillModel> getStarterSkills(String language) {
    final isEn = language == 'en';

    return [
      const SkillModel(
        id: 'starter-skill-1',
        name: 'Flutter & Dart',
        category: SkillCategory.hard,
        proficiency: 90,
      ),
      const SkillModel(
        id: 'starter-skill-2',
        name: 'Clean Architecture & Riverpod',
        category: SkillCategory.hard,
        proficiency: 85,
      ),
      const SkillModel(
        id: 'starter-skill-3',
        name: 'Drift (SQLite) & Supabase',
        category: SkillCategory.hard,
        proficiency: 80,
      ),
      SkillModel(
        id: 'starter-skill-4',
        name: isEn ? 'Problem Solving & Teamwork' : 'Giải quyết vấn đề & Làm việc nhóm',
        category: SkillCategory.soft,
        proficiency: 85,
      ),
    ];
  }

  static List<EducationModel> getStarterEducation(String language) {
    final isEn = language == 'en';
    final now = DateTime.now();

    return [
      EducationModel(
        id: 'starter-edu-1',
        institution: isEn
            ? 'Industrial University of Ho Chi Minh City'
            : 'Đại học Công nghiệp TP.HCM (IUH)',
        fieldOfStudy: isEn ? 'Software Engineering' : 'Kỹ thuật Phần mềm',
        degree: isEn ? "Bachelor's Degree" : 'Kỹ sư / Cử nhân',
        startDate: DateTime.utc(now.year - 3, 9, 1),
        endDate: DateTime.utc(now.year + 1, 6, 1),
        isCurrent: true,
        gpa: '3.2 / 4.0',
        achievements: isEn
            ? ['Top 10% Academic Honors', 'Member of IT Innovation Club']
            : ['Học bổng khuyến khích học tập', 'Thành viên CLB Sáng tạo CNTT'],
      ),
    ];
  }

  static List<CertificationModel> getStarterCertifications(String language) {
    final now = DateTime.now();

    return [
      CertificationModel(
        id: 'starter-cert-1',
        name: 'TOEIC Reading & Listening (650+)',
        issuer: 'ETS',
        score: '675',
        issueDate: DateTime.utc(now.year - 1, 5, 1),
      ),
    ];
  }
}
