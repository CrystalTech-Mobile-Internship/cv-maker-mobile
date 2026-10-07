class EducationModel {
  const EducationModel({
    this.id,
    required this.institution,
    this.degree = '',
    this.fieldOfStudy = '',
    this.startDate,
    this.endDate,
    this.gpa,
    this.achievements = const [],
  });

  final String? id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? gpa;
  final List<String> achievements;

  factory EducationModel.fromMap(Map<String, dynamic> map) => EducationModel(
    id: map['id'] as String?,
    institution: map['institution'] as String? ?? '',
    degree: map['degree'] as String? ?? '',
    fieldOfStudy: map['field_of_study'] as String? ?? '',
    startDate: _parseDate(map['start_date']),
    endDate: _parseDate(map['end_date']),
    gpa: _parseDouble(map['gpa']),
    achievements: _parseStrings(map['achievements']),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'institution': institution,
    'degree': degree,
    'field_of_study': fieldOfStudy,
    'start_date': startDate?.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'gpa': gpa,
    'achievements': achievements,
  };
}

DateTime? _parseDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

double? _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

List<String> _parseStrings(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}
