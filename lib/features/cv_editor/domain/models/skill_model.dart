class SkillModel {
  const SkillModel({
    this.id,
    required this.name,
    this.category = 'technical',
    this.proficiency,
  });

  final String? id;
  final String name;
  final String category;
  final int? proficiency;

  factory SkillModel.fromMap(Map<String, dynamic> map) => SkillModel(
    id: map['id'] as String?,
    name: map['name'] as String? ?? '',
    category: map['category'] as String? ?? 'technical',
    proficiency: (map['proficiency'] as num?)?.toInt(),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'category': category,
    'proficiency': proficiency,
  };
}
