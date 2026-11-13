class SummaryPolishRequest {
  const SummaryPolishRequest({
    required this.currentSummary,
    required this.targetRole,
    required this.language,
    this.skills = const [],
  });

  final String currentSummary;
  final String targetRole;
  final String language;
  final List<String> skills;

  Map<String, dynamic> toJson() => {
    'currentSummary': currentSummary,
    'targetRole': targetRole,
    'language': language,
    'skills': skills,
  };
}
