import '../../../cv_editor/domain/models/models.dart';

/// Builds a non-destructive presentation copy for empty template previews.
///
/// The returned CV is used only for rendering/exporting the current preview.
/// It never replaces the user's locally stored CV.
abstract final class CvSampleContentService {
  static bool hasMissingSections(CvModel cv) {
    final info = cv.personalInfo;
    return info.fullName.trim().isEmpty ||
        info.targetRole.trim().isEmpty ||
        info.email.trim().isEmpty ||
        cv.summary.trim().isEmpty ||
        cv.educations.isEmpty ||
        cv.educations.any(
          (item) =>
              item.institution.trim().isEmpty ||
              item.degree.trim().isEmpty ||
              item.fieldOfStudy.trim().isEmpty,
        ) ||
        cv.experiences.isEmpty ||
        cv.experiences.any(
          (item) =>
              item.jobTitle.trim().isEmpty ||
              item.company.trim().isEmpty ||
              item.bulletPoints.isEmpty,
        ) ||
        cv.skills.isEmpty ||
        cv.skills.any((item) => item.name.trim().isEmpty) ||
        cv.projects.isEmpty ||
        cv.projects.any(
          (item) =>
              item.name.trim().isEmpty ||
              item.role.trim().isEmpty ||
              item.description.trim().isEmpty,
        ) ||
        cv.certifications.isEmpty ||
        cv.certifications.any((item) => item.name.trim().isEmpty);
  }

  static CvModel fillMissing(CvModel cv) {
    final isEnglish = cv.language == 'en';
    final info = cv.personalInfo;
    return cv.copyWith(
      personalInfo: info.copyWith(
        fullName: _orSample(
          info.fullName,
          isEnglish ? 'YOUR FULL NAME' : 'HỌ VÀ TÊN CỦA BẠN',
        ),
        targetRole: _orSample(
          info.targetRole,
          isEnglish ? 'TARGET POSITION' : 'VỊ TRÍ ỨNG TUYỂN',
        ),
        email: _orSample(info.email, 'email@example.com'),
        phone: _orSample(info.phone, '09xx xxx xxx'),
        address: _orSample(
          info.address,
          isEnglish ? 'City, Country' : 'Thành phố, Việt Nam',
        ),
        linkedInUrl: _nullableOrSample(
          info.linkedInUrl,
          'linkedin.com/in/your-profile',
        ),
        githubUrl: _nullableOrSample(info.githubUrl, 'github.com/your-account'),
      ),
      summary: _orSample(
        cv.summary,
        isEnglish
            ? 'Write 2–3 concise sentences about your strengths, experience, and career goal.'
            : 'Viết 2–3 câu ngắn gọn về thế mạnh, kinh nghiệm và mục tiêu nghề nghiệp của bạn.',
      ),
      educations: cv.educations.isEmpty
          ? [
              EducationModel(
                id: 'sample-education',
                institution: isEnglish ? 'UNIVERSITY NAME' : 'TÊN TRƯỜNG',
                degree: isEnglish ? 'Degree' : 'Bậc đào tạo',
                fieldOfStudy: isEnglish ? 'Major' : 'Chuyên ngành',
                startDate: DateTime.utc(2022),
                endDate: DateTime.utc(2026),
                gpa: 'GPA: x.xx/4.0',
              ),
            ]
          : cv.educations
                .map(
                  (item) => item.copyWith(
                    institution: _orSample(
                      item.institution,
                      isEnglish ? 'UNIVERSITY NAME' : 'TÊN TRƯỜNG',
                    ),
                    degree: _orSample(
                      item.degree,
                      isEnglish ? 'Degree' : 'Bậc đào tạo',
                    ),
                    fieldOfStudy: _orSample(
                      item.fieldOfStudy,
                      isEnglish ? 'Major' : 'Chuyên ngành',
                    ),
                    achievements: item.achievements.isEmpty
                        ? [
                            isEnglish
                                ? 'Add an academic achievement or relevant activity.'
                                : 'Bổ sung thành tích học tập hoặc hoạt động liên quan.',
                          ]
                        : item.achievements,
                  ),
                )
                .toList(growable: false),
      experiences: cv.experiences.isEmpty
          ? [
              ExperienceModel(
                id: 'sample-experience',
                jobTitle: isEnglish ? 'JOB TITLE' : 'VỊ TRÍ CÔNG VIỆC',
                company: isEnglish ? 'Company name' : 'Tên công ty',
                location: isEnglish ? 'City' : 'Thành phố',
                startDate: DateTime.utc(2025, 1),
                endDate: DateTime.utc(2025, 6),
                bulletPoints: [
                  isEnglish
                      ? 'Describe a responsibility using a strong action verb.'
                      : 'Mô tả một nhiệm vụ bằng động từ hành động rõ ràng.',
                  isEnglish
                      ? 'Add a measurable result or impact when possible.'
                      : 'Bổ sung kết quả hoặc tác động có số liệu nếu có.',
                ],
              ),
            ]
          : cv.experiences
                .map(
                  (item) => item.copyWith(
                    jobTitle: _orSample(
                      item.jobTitle,
                      isEnglish ? 'JOB TITLE' : 'VỊ TRÍ CÔNG VIỆC',
                    ),
                    company: _orSample(
                      item.company,
                      isEnglish ? 'Company name' : 'Tên công ty',
                    ),
                    location: _orSample(
                      item.location,
                      isEnglish ? 'City' : 'Thành phố',
                    ),
                    bulletPoints: item.bulletPoints.isEmpty
                        ? [
                            isEnglish
                                ? 'Describe your responsibility and measurable result.'
                                : 'Mô tả nhiệm vụ và kết quả có thể đo lường.',
                          ]
                        : item.bulletPoints,
                  ),
                )
                .toList(growable: false),
      skills: cv.skills.isEmpty
          ? [
              SkillModel(
                id: 'sample-skill-1',
                name: isEnglish ? 'Professional skill' : 'Kỹ năng chuyên môn',
                category: SkillCategory.hard,
                proficiency: 80,
              ),
              SkillModel(
                id: 'sample-skill-2',
                name: isEnglish ? 'Communication' : 'Giao tiếp',
                category: SkillCategory.soft,
                proficiency: 75,
              ),
            ]
          : cv.skills
                .map(
                  (item) => item.name.trim().isEmpty
                      ? item.copyWith(
                          name: isEnglish
                              ? 'Professional skill'
                              : 'Kỹ năng chuyên môn',
                        )
                      : item,
                )
                .toList(growable: false),
      projects: cv.projects.isEmpty
          ? [
              ProjectModel(
                id: 'sample-project',
                name: isEnglish ? 'PROJECT NAME' : 'TÊN DỰ ÁN',
                role: isEnglish ? 'Your role' : 'Vai trò của bạn',
                technologies: const ['Technology 1', 'Technology 2'],
                sourceUrl: 'github.com/your-account/project',
                startDate: DateTime.utc(2025, 1),
                endDate: DateTime.utc(2025, 4),
                teamSize: 3,
                description: isEnglish
                    ? 'Explain the problem and your main contribution.\nMention a concrete result or lesson learned.'
                    : 'Trình bày bài toán và đóng góp chính của bạn.\nNêu kết quả cụ thể hoặc bài học đạt được.',
              ),
            ]
          : cv.projects
                .map(
                  (item) => item.copyWith(
                    name: _orSample(
                      item.name,
                      isEnglish ? 'PROJECT NAME' : 'TÊN DỰ ÁN',
                    ),
                    role: _orSample(
                      item.role,
                      isEnglish ? 'Your role' : 'Vai trò của bạn',
                    ),
                    technologies: item.technologies.isEmpty
                        ? const ['Technology 1', 'Technology 2']
                        : item.technologies,
                    description: _orSample(
                      item.description,
                      isEnglish
                          ? 'Explain the problem, your contribution, and the result.'
                          : 'Trình bày bài toán, đóng góp của bạn và kết quả.',
                    ),
                    sourceUrl: _nullableOrSample(
                      item.sourceUrl,
                      'github.com/your-account/project',
                    ),
                  ),
                )
                .toList(growable: false),
      certifications: cv.certifications.isEmpty
          ? [
              CertificationModel(
                id: 'sample-certification',
                name: isEnglish ? 'CERTIFICATE NAME' : 'TÊN CHỨNG CHỈ',
                issuer: isEnglish ? 'Issuing organization' : 'Đơn vị cấp',
                score: isEnglish ? 'Score (optional)' : 'Điểm (nếu có)',
              ),
            ]
          : cv.certifications
                .map(
                  (item) => item.copyWith(
                    name: _orSample(
                      item.name,
                      isEnglish ? 'CERTIFICATE NAME' : 'TÊN CHỨNG CHỈ',
                    ),
                    issuer: _orSample(
                      item.issuer,
                      isEnglish ? 'Issuing organization' : 'Đơn vị cấp',
                    ),
                  ),
                )
                .toList(growable: false),
    );
  }

  static String _orSample(String value, String sample) =>
      value.trim().isEmpty ? sample : value;

  static String _nullableOrSample(String? value, String sample) =>
      value == null || value.trim().isEmpty ? sample : value;
}
