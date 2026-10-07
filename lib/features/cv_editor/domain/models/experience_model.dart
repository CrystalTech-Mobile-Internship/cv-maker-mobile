class ExperienceModel {
  const ExperienceModel({
    this.id,
    required this.company,
    required this.position,
    this.location = '',
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.bullets = const [],
  });

  final String? id;
  final String company;
  final String position;
  final String location;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final List<String> bullets;

  factory ExperienceModel.fromMap(Map<String, dynamic> map) => ExperienceModel(
    id: map['id'] as String?,
    company: map['company'] as String? ?? '',
    position: map['position'] as String? ?? '',
    location: map['location'] as String? ?? '',
    startDate: _experienceDate(map['start_date']),
    endDate: _experienceDate(map['end_date']),
    isCurrent: map['is_current'] as bool? ?? false,
    bullets:
        (map['bullets'] as List?)?.whereType<String>().toList() ?? const [],
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'company': company,
    'position': position,
    'location': location,
    'start_date': startDate?.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'is_current': isCurrent,
    'bullets': bullets,
  };
}

DateTime? _experienceDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
