import '../../domain/models/models.dart';

/// Converts the storage-neutral CV domain models to and from Supabase rows.
///
/// The domain models continue to use camelCase and local/offline fields such
/// as [CvModel.isSynced]. Supabase columns use snake_case, while section data
/// is stored as JSON in `cv_items.payload`.
final class CvSupabaseMapper {
  const CvSupabaseMapper._();

  static CvModel fromCvRow(Map<String, dynamic> row) {
    final updatedAt = _date(row['updated_at']) ?? DateTime.now().toUtc();
    final sections = _maps(row['cv_sections']);
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final section in sections) {
      final sectionType = _string(section['section_type']);
      if (sectionType == null) continue;

      final items = <Map<String, dynamic>>[];
      for (final item in _maps(section['cv_items'])) {
        final payload = _map(item['payload']) ?? <String, dynamic>{};
        if (!payload.containsKey('id') && item['id'] != null) {
          payload['id'] = item['id'];
        }
        items.add(payload);
      }
      grouped[sectionType] = items;
    }

    return CvModel(
      id: _string(row['id']) ?? 'remote-cv',
      userId: _string(row['user_id']),
      title: _string(row['title']) ?? 'CV chưa đặt tên',
      templateId: _string(row['template_id']) ?? 'harvard_ats',
      primaryColor: _string(row['primary_color']) ?? '#1E293B',
      fontSizeScale: _number(row['font_size_scale']) ?? 1,
      personalInfo: _personalInfoFromMap(_map(row['personal_info'])),
      summary: _string(row['summary']) ?? '',
      educations: (grouped['education'] ?? const [])
          .map(_educationFromMap)
          .toList(growable: false),
      experiences: (grouped['experience'] ?? const [])
          .map(_experienceFromMap)
          .toList(growable: false),
      skills: (grouped['skills'] ?? const [])
          .map(_skillFromMap)
          .toList(growable: false),
      projects: (grouped['projects'] ?? const [])
          .map(_projectFromMap)
          .toList(growable: false),
      isSynced: true,
      createdAt: _date(row['created_at']) ?? updatedAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> toCvRow(CvModel cv, {required String userId}) {
    final row = <String, dynamic>{
      'user_id': userId,
      'title': cv.title,
      'template_id': cv.templateId,
      'primary_color': cv.primaryColor,
      'font_size_scale': cv.fontSizeScale,
      'summary': cv.summary,
      'personal_info': _personalInfoToMap(cv.personalInfo),
    };

    // Local drafts may use IDs such as "cv-student-001", which are not valid
    // PostgreSQL UUIDs. Let Supabase generate the ID for those drafts.
    if (_isUuid(cv.id)) row['id'] = cv.id;
    return row;
  }

  static List<CvSectionPayload> toSections(CvModel cv) {
    return [
      CvSectionPayload(
        type: 'education',
        title: 'Học vấn',
        items: cv.educations.map(_educationToMap).toList(growable: false),
      ),
      CvSectionPayload(
        type: 'experience',
        title: 'Kinh nghiệm',
        items: cv.experiences.map(_experienceToMap).toList(growable: false),
      ),
      CvSectionPayload(
        type: 'skills',
        title: 'Kỹ năng',
        items: cv.skills.map(_skillToMap).toList(growable: false),
      ),
      CvSectionPayload(
        type: 'projects',
        title: 'Dự án',
        items: cv.projects.map(_projectToMap).toList(growable: false),
      ),
    ];
  }

  static PersonalInfoModel _personalInfoFromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return PersonalInfoModel(
      fullName: _firstString(data, ['fullName', 'full_name']) ?? '',
      targetRole:
          _firstString(data, ['targetRole', 'target_role', 'role']) ?? '',
      email: _string(data['email']) ?? '',
      phone: _string(data['phone']) ?? '',
      address: _firstString(data, ['address', 'location']) ?? '',
      linkedInUrl: _firstString(data, ['linkedInUrl', 'linked_in_url']),
      githubUrl: _firstString(data, ['githubUrl', 'github_url']),
      avatarPath: _firstString(data, ['avatarPath', 'avatar_path']),
    );
  }

  static Map<String, dynamic> _personalInfoToMap(PersonalInfoModel info) => {
    'full_name': info.fullName,
    'target_role': info.targetRole,
    'email': info.email,
    'phone': info.phone,
    'address': info.address,
    'linked_in_url': info.linkedInUrl,
    'github_url': info.githubUrl,
    'avatar_path': info.avatarPath,
  };

  static EducationModel _educationFromMap(Map<String, dynamic> map) {
    return EducationModel(
      id: _requiredId(map),
      institution: _string(map['institution']) ?? '',
      degree: _string(map['degree']) ?? '',
      fieldOfStudy: _firstString(map, ['fieldOfStudy', 'field_of_study']) ?? '',
      startDate: _firstDate(map, ['startDate', 'start_date']) ?? _epoch,
      endDate: _firstDate(map, ['endDate', 'end_date']),
      isCurrent: _boolean(map['isCurrent'] ?? map['is_current']),
      gpa: _string(map['gpa']),
      achievements: _strings(map['achievements']),
    );
  }

  static Map<String, dynamic> _educationToMap(EducationModel education) => {
    ...education.toJson(),
  };

  static ExperienceModel _experienceFromMap(Map<String, dynamic> map) {
    return ExperienceModel(
      id: _requiredId(map),
      jobTitle: _firstString(map, ['jobTitle', 'job_title', 'position']) ?? '',
      company: _string(map['company']) ?? '',
      location: _string(map['location']) ?? '',
      startDate: _firstDate(map, ['startDate', 'start_date']) ?? _epoch,
      endDate: _firstDate(map, ['endDate', 'end_date']),
      isCurrent: _boolean(map['isCurrent'] ?? map['is_current']),
      bulletPoints: _strings(
        map['bulletPoints'] ?? map['bullet_points'] ?? map['bullets'],
      ),
    );
  }

  static Map<String, dynamic> _experienceToMap(ExperienceModel experience) => {
    ...experience.toJson(),
  };

  static SkillModel _skillFromMap(Map<String, dynamic> map) {
    final category = _string(map['category'])?.toLowerCase();
    return SkillModel(
      id: _requiredId(map),
      name: _string(map['name']) ?? '',
      category: category == SkillCategory.soft.name
          ? SkillCategory.soft
          : SkillCategory.hard,
      proficiency: _number(map['proficiency'])?.round() ?? 0,
    );
  }

  static Map<String, dynamic> _skillToMap(SkillModel skill) => skill.toJson();

  static ProjectModel _projectFromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: _requiredId(map),
      name: _string(map['name']) ?? '',
      role: _string(map['role']) ?? '',
      description: _string(map['description']) ?? '',
      technologies: _strings(map['technologies']),
      demoUrl: _firstString(map, ['demoUrl', 'demo_url']),
      sourceUrl: _firstString(map, ['sourceUrl', 'source_url']),
      startDate: _firstDate(map, ['startDate', 'start_date']),
      endDate: _firstDate(map, ['endDate', 'end_date']),
    );
  }

  static Map<String, dynamic> _projectToMap(ProjectModel project) => {
    ...project.toJson(),
  };

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  static String _requiredId(Map<String, dynamic> map) =>
      _string(map['id']) ?? 'remote-item';

  static String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = _string(map[key]);
      if (value != null) return value;
    }
    return null;
  }

  static DateTime? _firstDate(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = _date(map[key]);
      if (value != null) return value;
    }
    return null;
  }

  static String? _string(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    if (value is num) return value.toString();
    return null;
  }

  static double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static bool _boolean(dynamic value) => value == true || value == 'true';

  static DateTime? _date(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }

  static bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  static final _epoch = DateTime.utc(1970);
}

final class CvSectionPayload {
  const CvSectionPayload({
    required this.type,
    required this.title,
    required this.items,
  });

  final String type;
  final String title;
  final List<Map<String, dynamic>> items;
}
