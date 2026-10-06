const _unsetExperienceValue = Object();

/// One employment or internship entry in a CV.
class ExperienceModel {
  ExperienceModel({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.startDate,
    this.location = '',
    this.endDate,
    this.isCurrent = false,
    List<String> bulletPoints = const [],
  }) : bulletPoints = List.unmodifiable(bulletPoints);

  final String id;
  final String jobTitle;
  final String company;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final List<String> bulletPoints;

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    return ExperienceModel(
      id: json['id'] as String,
      jobTitle: json['jobTitle'] as String? ?? '',
      company: json['company'] as String? ?? '',
      location: json['location'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String).toUtc(),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String).toUtc(),
      isCurrent: json['isCurrent'] as bool? ?? false,
      bulletPoints: List<String>.from(
        json['bulletPoints'] as List<dynamic>? ?? const [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobTitle': jobTitle,
      'company': company,
      'location': location,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate?.toUtc().toIso8601String(),
      'isCurrent': isCurrent,
      'bulletPoints': bulletPoints,
    };
  }

  ExperienceModel copyWith({
    String? id,
    String? jobTitle,
    String? company,
    String? location,
    DateTime? startDate,
    Object? endDate = _unsetExperienceValue,
    bool? isCurrent,
    List<String>? bulletPoints,
  }) {
    return ExperienceModel(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: identical(endDate, _unsetExperienceValue)
          ? this.endDate
          : endDate as DateTime?,
      isCurrent: isCurrent ?? this.isCurrent,
      bulletPoints: bulletPoints ?? this.bulletPoints,
    );
  }
}
