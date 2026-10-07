enum SkillCategory {
  hard,
  soft;

  static SkillCategory fromJson(String value) {
    return SkillCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => throw FormatException('Unknown skill category: $value'),
    );
  }
}

/// One skill tag and its optional proficiency score from 0 to 100.
class SkillModel {
  const SkillModel({
    required this.id,
    required this.name,
    required this.category,
    this.proficiency = 0,
  }) : assert(
         proficiency >= 0 && proficiency <= 100,
         'proficiency must be between 0 and 100',
       );

  final String id;
  final String name;
  final SkillCategory category;
  final int proficiency;

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      category: SkillCategory.fromJson(json['category'] as String),
      proficiency: json['proficiency'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'proficiency': proficiency,
    };
  }

  SkillModel copyWith({
    String? id,
    String? name,
    SkillCategory? category,
    int? proficiency,
  }) {
    return SkillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      proficiency: proficiency ?? this.proficiency,
    );
  }
}
