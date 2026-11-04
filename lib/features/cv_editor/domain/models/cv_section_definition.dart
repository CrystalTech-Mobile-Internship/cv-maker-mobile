import 'package:flutter/material.dart';

/// Metadata definition for modular CV sections.
class CvSectionDefinition {
  const CvSectionDefinition({
    required this.id,
    required this.titleVi,
    required this.titleEn,
    required this.icon,
    required this.hintVi,
    required this.hintEn,
  });

  final String id;
  final String titleVi;
  final String titleEn;
  final IconData icon;
  final String hintVi;
  final String hintEn;

  String title(String language) => language == 'en' ? titleEn : titleVi;
  String hint(String language) => language == 'en' ? hintEn : hintVi;

  static const summary = CvSectionDefinition(
    id: 'summary',
    titleVi: 'Mục tiêu nghề nghiệp',
    titleEn: 'Professional Summary',
    icon: Icons.person_outline_rounded,
    hintVi: 'Tóm tắt thế mạnh, mục tiêu và giá trị bạn mang lại',
    hintEn: 'Highlight your background, core strengths, and career objectives',
  );

  static const experience = CvSectionDefinition(
    id: 'experience',
    titleVi: 'Kinh nghiệm làm việc',
    titleEn: 'Work Experience',
    icon: Icons.work_outline_rounded,
    hintVi: 'Các công ty, vị trí, trách nhiệm và thành tựu đã đạt được',
    hintEn: 'Companies, roles, key accomplishments, and measurable results',
  );

  static const projects = CvSectionDefinition(
    id: 'projects',
    titleVi: 'Dự án nổi bật',
    titleEn: 'Key Projects',
    icon: Icons.rocket_launch_outlined,
    hintVi: 'Sản phẩm, ứng dụng cá nhân hoặc nhóm, công nghệ sử dụng',
    hintEn: 'Notable applications, tech stacks, links, and key contributions',
  );

  static const education = CvSectionDefinition(
    id: 'education',
    titleVi: 'Học vấn & Bằng cấp',
    titleEn: 'Education',
    icon: Icons.school_outlined,
    hintVi: 'Trường đại học, chuyên ngành, GPA và thời gian theo học',
    hintEn: 'Universities, majors, GPA, honors, and study periods',
  );

  static const skills = CvSectionDefinition(
    id: 'skills',
    titleVi: 'Kỹ năng chuyên môn',
    titleEn: 'Skills',
    icon: Icons.auto_awesome_outlined,
    hintVi: 'Ngôn ngữ lập trình, framework, công cụ và kỹ năng mềm',
    hintEn: 'Programming languages, frameworks, developer tools, and soft skills',
  );

  static const certifications = CvSectionDefinition(
    id: 'certifications',
    titleVi: 'Chứng chỉ & Giải thưởng',
    titleEn: 'Certifications & Honors',
    icon: Icons.workspace_premium_outlined,
    hintVi: 'Chứng chỉ ngoại ngữ (TOEIC, IELTS), chứng chỉ IT hoặc giải thưởng',
    hintEn: 'Language certificates, tech certifications, or academic awards',
  );

  static const List<CvSectionDefinition> all = [
    summary,
    experience,
    projects,
    education,
    skills,
    certifications,
  ];

  static CvSectionDefinition? findById(String id) {
    for (final def in all) {
      if (def.id == id) return def;
    }
    return null;
  }
}
