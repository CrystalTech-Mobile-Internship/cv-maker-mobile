import 'education_model.dart';
import 'experience_model.dart';
import 'project_model.dart';
import 'skill_model.dart';

class PersonalInfoModel {
  const PersonalInfoModel({
    this.fullName = '',
    this.role = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.website = '',
  });

  final String fullName;
  final String role;
  final String email;
  final String phone;
  final String location;
  final String website;

  factory PersonalInfoModel.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return PersonalInfoModel(
      fullName: data['full_name'] as String? ?? '',
      role: data['role'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      location: data['location'] as String? ?? '',
      website: data['website'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'full_name': fullName,
    'role': role,
    'email': email,
    'phone': phone,
    'location': location,
    'website': website,
  };
}

class CvModel {
  const CvModel({
    this.id,
    this.userId,
    required this.title,
    this.templateId,
    this.primaryColor = '#1E293B',
    this.fontSizeScale = 1.0,
    this.summary = '',
    this.personalInfo = const PersonalInfoModel(),
    this.educations = const [],
    this.experiences = const [],
    this.skills = const [],
    this.projects = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? userId;
  final String title;
  final String? templateId;
  final String primaryColor;
  final double fontSizeScale;
  final String summary;
  final PersonalInfoModel personalInfo;
  final List<EducationModel> educations;
  final List<ExperienceModel> experiences;
  final List<SkillModel> skills;
  final List<ProjectModel> projects;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CvModel.fromMap(Map<String, dynamic> map) {
    return CvModel(
      id: map['id'] as String?,
      userId: map['user_id'] as String?,
      title: map['title'] as String? ?? 'CV chưa đặt tên',
      templateId: map['template_id'] as String?,
      primaryColor: map['primary_color'] as String? ?? '#1E293B',
      fontSizeScale: _asDouble(map['font_size_scale']) ?? 1.0,
      summary: map['summary'] as String? ?? '',
      personalInfo: PersonalInfoModel.fromMap(_asMap(map['personal_info'])),
      createdAt: _asDateTime(map['created_at']),
      updatedAt: _asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap({String? ownerId}) => {
    if (id != null) 'id': id,
    'user_id': ownerId ?? userId,
    'title': title,
    'template_id': templateId,
    'primary_color': primaryColor,
    'font_size_scale': fontSizeScale,
    'summary': summary,
    'personal_info': personalInfo.toMap(),
  };

  CvModel copyWith({String? id, String? userId}) => CvModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title,
    templateId: templateId,
    primaryColor: primaryColor,
    fontSizeScale: fontSizeScale,
    summary: summary,
    personalInfo: personalInfo,
    educations: educations,
    experiences: experiences,
    skills: skills,
    projects: projects,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
