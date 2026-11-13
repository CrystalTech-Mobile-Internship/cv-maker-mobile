import 'certification_model.dart';
import 'education_model.dart';
import 'experience_model.dart';
import 'personal_info_model.dart';
import 'project_model.dart';
import 'skill_model.dart';

const _unsetCvValue = Object();

/// Aggregate root containing all editable and sync-related CV data.
class CvModel {
  CvModel({
    required this.id,
    required this.title,
    required this.templateId,
    this.language = 'vi',
    required this.primaryColor,
    required this.fontSizeScale,
    required this.personalInfo,
    required this.summary,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    List<EducationModel> educations = const [],
    List<ExperienceModel> experiences = const [],
    List<SkillModel> skills = const [],
    List<ProjectModel> projects = const [],
    List<CertificationModel> certifications = const [],
    List<String> sectionOrder = defaultSectionOrder,
    List<String> hiddenSections = const [],
  }) : educations = List.unmodifiable(educations),
       experiences = List.unmodifiable(experiences),
       skills = List.unmodifiable(skills),
       projects = List.unmodifiable(projects),
       certifications = List.unmodifiable(certifications),
       sectionOrder = List.unmodifiable(sectionOrder),
       hiddenSections = List.unmodifiable(hiddenSections);

  static const List<String> defaultSectionOrder = [
    'summary',
    'experience',
    'projects',
    'education',
    'skills',
    'certifications',
  ];

  final String id;
  final String? userId;
  final String title;
  final String templateId;
  final String language; // 'vi' or 'en'
  final String primaryColor;
  final double fontSizeScale;
  final PersonalInfoModel personalInfo;
  final String summary;
  final List<EducationModel> educations;
  final List<ExperienceModel> experiences;
  final List<SkillModel> skills;
  final List<ProjectModel> projects;
  final List<CertificationModel> certifications;
  final List<String> sectionOrder;
  final List<String> hiddenSections;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<String> get effectiveSectionOrder {
    final current = List<String>.from(sectionOrder);
    for (final section in defaultSectionOrder) {
      if (!current.contains(section)) {
        current.add(section);
      }
    }
    return current;
  }

  List<String> get visibleSectionOrder {
    return effectiveSectionOrder
        .where((section) => !hiddenSections.contains(section))
        .toList();
  }

  bool isSectionVisible(String section) => !hiddenSections.contains(section);

  factory CvModel.empty({
    required String id,
    String? userId,
    String language = 'vi',
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc();

    return CvModel(
      id: id,
      userId: userId,
      title: 'CV chưa đặt tên',
      templateId: 'harvard_ats',
      language: language,
      primaryColor: '#1E293B',
      fontSizeScale: 1,
      personalInfo: const PersonalInfoModel(),
      summary: '',
      isSynced: false,
      createdAt: timestamp,
      updatedAt: timestamp,
      sectionOrder: defaultSectionOrder,
      hiddenSections: const [],
    );
  }

  factory CvModel.fromJson(Map<String, dynamic> json) {
    final updatedAt = DateTime.parse(json['updatedAt'] as String).toUtc();

    return CvModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      title: json['title'] as String? ?? 'CV chưa đặt tên',
      templateId: json['templateId'] as String? ?? 'harvard_ats',
      language: json['language'] as String? ?? 'vi',
      primaryColor: json['primaryColor'] as String? ?? '#1E293B',
      fontSizeScale: (json['fontSizeScale'] as num? ?? 1).toDouble(),
      personalInfo: PersonalInfoModel.fromJson(
        Map<String, dynamic>.from(
          json['personalInfo'] as Map<dynamic, dynamic>? ?? const {},
        ),
      ),
      summary: json['summary'] as String? ?? '',
      educations: _readModelList(json['educations'], EducationModel.fromJson),
      experiences: _readModelList(
        json['experiences'],
        ExperienceModel.fromJson,
      ),
      skills: _readModelList(json['skills'], SkillModel.fromJson),
      projects: _readModelList(json['projects'], ProjectModel.fromJson),
      certifications: _readModelList(
        json['certifications'],
        CertificationModel.fromJson,
      ),
      sectionOrder:
          (json['sectionOrder'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          defaultSectionOrder,
      hiddenSections:
          (json['hiddenSections'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      isSynced: json['isSynced'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? updatedAt
          : DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'templateId': templateId,
      'language': language,
      'primaryColor': primaryColor,
      'fontSizeScale': fontSizeScale,
      'personalInfo': personalInfo.toJson(),
      'summary': summary,
      'educations': educations.map((item) => item.toJson()).toList(),
      'experiences': experiences.map((item) => item.toJson()).toList(),
      'skills': skills.map((item) => item.toJson()).toList(),
      'projects': projects.map((item) => item.toJson()).toList(),
      'certifications': certifications.map((item) => item.toJson()).toList(),
      'sectionOrder': sectionOrder,
      'hiddenSections': hiddenSections,
      'isSynced': isSynced,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  CvModel copyWith({
    String? id,
    Object? userId = _unsetCvValue,
    String? title,
    String? templateId,
    String? language,
    String? primaryColor,
    double? fontSizeScale,
    PersonalInfoModel? personalInfo,
    String? summary,
    List<EducationModel>? educations,
    List<ExperienceModel>? experiences,
    List<SkillModel>? skills,
    List<ProjectModel>? projects,
    List<CertificationModel>? certifications,
    List<String>? sectionOrder,
    List<String>? hiddenSections,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CvModel(
      id: id ?? this.id,
      userId: identical(userId, _unsetCvValue)
          ? this.userId
          : userId as String?,
      title: title ?? this.title,
      templateId: templateId ?? this.templateId,
      language: language ?? this.language,
      primaryColor: primaryColor ?? this.primaryColor,
      fontSizeScale: fontSizeScale ?? this.fontSizeScale,
      personalInfo: personalInfo ?? this.personalInfo,
      summary: summary ?? this.summary,
      educations: educations ?? this.educations,
      experiences: experiences ?? this.experiences,
      skills: skills ?? this.skills,
      projects: projects ?? this.projects,
      certifications: certifications ?? this.certifications,
      sectionOrder: sectionOrder ?? this.sectionOrder,
      hiddenSections: hiddenSections ?? this.hiddenSections,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

List<T> _readModelList<T>(
  Object? value,
  T Function(Map<String, dynamic>) fromJson,
) {
  final items = value as List<dynamic>? ?? const [];

  return items
      .map(
        (item) =>
            fromJson(Map<String, dynamic>.from(item as Map<dynamic, dynamic>)),
      )
      .toList();
}
