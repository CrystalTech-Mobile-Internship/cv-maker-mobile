import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/certification_model.dart';
import '../../../cv_editor/domain/models/education_model.dart';
import '../../../cv_editor/domain/models/experience_model.dart';
import '../../../cv_editor/domain/models/personal_info_model.dart';
import '../../../cv_editor/domain/models/project_model.dart';
import '../../../cv_editor/domain/models/skill_model.dart';

final class ResumeEducationDraft {
  const ResumeEducationDraft({
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.gpa,
    this.achievements = const [],
  });

  final String institution;
  final String degree;
  final String fieldOfStudy;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? gpa;
  final List<String> achievements;
}

final class ResumeExperienceDraft {
  const ResumeExperienceDraft({
    required this.jobTitle,
    required this.company,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.bulletPoints = const [],
  });

  final String jobTitle;
  final String company;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final List<String> bulletPoints;
}

final class ResumeProjectDraft {
  const ResumeProjectDraft({
    required this.name,
    required this.role,
    this.description = '',
    this.technologies = const [],
    this.sourceUrl,
    this.startDate,
    this.endDate,
  });

  final String name;
  final String role;
  final String description;
  final List<String> technologies;
  final String? sourceUrl;
  final DateTime? startDate;
  final DateTime? endDate;
}

final class ResumeCertificationDraft {
  const ResumeCertificationDraft({
    required this.name,
    this.issuer = '',
    this.score,
    this.issueDate,
    this.credentialUrl,
  });

  final String name;
  final String issuer;
  final String? score;
  final DateTime? issueDate;
  final String? credentialUrl;
}

final class ResumeImportDraft {
  const ResumeImportDraft({
    required this.sourceName,
    required this.rawText,
    required this.fullName,
    required this.targetRole,
    required this.email,
    required this.phone,
    required this.address,
    required this.summary,
    required this.skills,
    required this.educations,
    required this.experiences,
    required this.projects,
    required this.certifications,
    required this.warnings,
  });

  final String sourceName;
  final String rawText;
  final String fullName;
  final String targetRole;
  final String email;
  final String phone;
  final String address;
  final String summary;
  final List<String> skills;
  final List<ResumeEducationDraft> educations;
  final List<ResumeExperienceDraft> experiences;
  final List<ResumeProjectDraft> projects;
  final List<ResumeCertificationDraft> certifications;
  final List<String> warnings;

  CvModel toCv({
    required String id,
    required String title,
    required String templateId,
    required String primaryColor,
    required String language,
    required DateTime now,
    String? userId,
    String? correctedFullName,
    String? correctedTargetRole,
    String? correctedEmail,
    String? correctedPhone,
    String? correctedAddress,
    String? correctedSummary,
  }) {
    return CvModel(
      id: id,
      userId: userId,
      title: title,
      templateId: templateId,
      language: language,
      primaryColor: primaryColor,
      fontSizeScale: 1,
      personalInfo: PersonalInfoModel(
        fullName: correctedFullName ?? fullName,
        targetRole: correctedTargetRole ?? targetRole,
        email: correctedEmail ?? email,
        phone: correctedPhone ?? phone,
        address: correctedAddress ?? address,
      ),
      summary: correctedSummary ?? summary,
      skills: [
        for (var index = 0; index < skills.length; index++)
          SkillModel(
            id: '$id-skill-$index',
            name: skills[index],
            category: SkillCategory.hard,
          ),
      ],
      educations: [
        for (var index = 0; index < educations.length; index++)
          EducationModel(
            id: '$id-education-$index',
            institution: educations[index].institution,
            degree: educations[index].degree,
            fieldOfStudy: educations[index].fieldOfStudy,
            startDate: educations[index].startDate,
            endDate: educations[index].endDate,
            isCurrent: educations[index].isCurrent,
            gpa: educations[index].gpa,
            achievements: educations[index].achievements,
          ),
      ],
      experiences: [
        for (var index = 0; index < experiences.length; index++)
          ExperienceModel(
            id: '$id-experience-$index',
            jobTitle: experiences[index].jobTitle,
            company: experiences[index].company,
            startDate: experiences[index].startDate,
            endDate: experiences[index].endDate,
            isCurrent: experiences[index].isCurrent,
            bulletPoints: experiences[index].bulletPoints,
          ),
      ],
      projects: [
        for (var index = 0; index < projects.length; index++)
          ProjectModel(
            id: '$id-project-$index',
            name: projects[index].name,
            role: projects[index].role,
            description: projects[index].description,
            technologies: projects[index].technologies,
            sourceUrl: projects[index].sourceUrl,
            startDate: projects[index].startDate,
            endDate: projects[index].endDate,
          ),
      ],
      certifications: [
        for (var index = 0; index < certifications.length; index++)
          CertificationModel(
            id: '$id-certification-$index',
            name: certifications[index].name,
            issuer: certifications[index].issuer,
            score: certifications[index].score,
            issueDate: certifications[index].issueDate,
            credentialUrl: certifications[index].credentialUrl,
          ),
      ],
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}
