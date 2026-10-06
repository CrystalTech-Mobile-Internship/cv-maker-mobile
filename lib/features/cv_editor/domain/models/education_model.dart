const _unsetEducationValue = Object();

/// One education entry in a CV.
class EducationModel {
  EducationModel({
    required this.id,
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.gpa,
    List<String> achievements = const [],
  }) : achievements = List.unmodifiable(achievements);

  final String id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? gpa;
  final List<String> achievements;

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      id: json['id'] as String,
      institution: json['institution'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      fieldOfStudy: json['fieldOfStudy'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String).toUtc(),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String).toUtc(),
      isCurrent: json['isCurrent'] as bool? ?? false,
      gpa: json['gpa'] as String?,
      achievements: List<String>.from(
        json['achievements'] as List<dynamic>? ?? const [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institution': institution,
      'degree': degree,
      'fieldOfStudy': fieldOfStudy,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate?.toUtc().toIso8601String(),
      'isCurrent': isCurrent,
      'gpa': gpa,
      'achievements': achievements,
    };
  }

  EducationModel copyWith({
    String? id,
    String? institution,
    String? degree,
    String? fieldOfStudy,
    DateTime? startDate,
    Object? endDate = _unsetEducationValue,
    bool? isCurrent,
    Object? gpa = _unsetEducationValue,
    List<String>? achievements,
  }) {
    return EducationModel(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      startDate: startDate ?? this.startDate,
      endDate: identical(endDate, _unsetEducationValue)
          ? this.endDate
          : endDate as DateTime?,
      isCurrent: isCurrent ?? this.isCurrent,
      gpa: identical(gpa, _unsetEducationValue) ? this.gpa : gpa as String?,
      achievements: achievements ?? this.achievements,
    );
  }
}
