class ProjectModel {
  const ProjectModel({
    this.id,
    required this.name,
    this.role = '',
    this.technologies = const [],
    this.description = '',
    this.sourceUrl,
    this.demoUrl,
  });

  final String? id;
  final String name;
  final String role;
  final List<String> technologies;
  final String description;
  final String? sourceUrl;
  final String? demoUrl;

  factory ProjectModel.fromMap(Map<String, dynamic> map) => ProjectModel(
    id: map['id'] as String?,
    name: map['name'] as String? ?? '',
    role: map['role'] as String? ?? '',
    technologies:
        (map['technologies'] as List?)?.whereType<String>().toList() ??
        const [],
    description: map['description'] as String? ?? '',
    sourceUrl: map['source_url'] as String?,
    demoUrl: map['demo_url'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'role': role,
    'technologies': technologies,
    'description': description,
    'source_url': sourceUrl,
    'demo_url': demoUrl,
  };
}
