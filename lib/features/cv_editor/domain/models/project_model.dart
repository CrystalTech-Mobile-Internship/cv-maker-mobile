const _unsetProjectValue = Object();

/// One personal, academic, or professional project in a CV.
class ProjectModel {
  ProjectModel({
    required this.id,
    required this.name,
    required this.role,
    this.description = '',
    List<String> technologies = const [],
    this.demoUrl,
    this.sourceUrl,
    this.startDate,
    this.endDate,
  }) : technologies = List.unmodifiable(technologies);

  final String id;
  final String name;
  final String role;
  final String description;
  final List<String> technologies;
  final String? demoUrl;
  final String? sourceUrl;
  final DateTime? startDate;
  final DateTime? endDate;

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      description: json['description'] as String? ?? '',
      technologies: List<String>.from(
        json['technologies'] as List<dynamic>? ?? const [],
      ),
      demoUrl: json['demoUrl'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String).toUtc(),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'description': description,
      'technologies': technologies,
      'demoUrl': demoUrl,
      'sourceUrl': sourceUrl,
      'startDate': startDate?.toUtc().toIso8601String(),
      'endDate': endDate?.toUtc().toIso8601String(),
    };
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? role,
    String? description,
    List<String>? technologies,
    Object? demoUrl = _unsetProjectValue,
    Object? sourceUrl = _unsetProjectValue,
    Object? startDate = _unsetProjectValue,
    Object? endDate = _unsetProjectValue,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      description: description ?? this.description,
      technologies: technologies ?? this.technologies,
      demoUrl: identical(demoUrl, _unsetProjectValue)
          ? this.demoUrl
          : demoUrl as String?,
      sourceUrl: identical(sourceUrl, _unsetProjectValue)
          ? this.sourceUrl
          : sourceUrl as String?,
      startDate: identical(startDate, _unsetProjectValue)
          ? this.startDate
          : startDate as DateTime?,
      endDate: identical(endDate, _unsetProjectValue)
          ? this.endDate
          : endDate as DateTime?,
    );
  }
}
