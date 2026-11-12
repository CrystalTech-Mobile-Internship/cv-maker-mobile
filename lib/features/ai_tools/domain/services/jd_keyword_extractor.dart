/// Offline keyword extractor for job descriptions.
///
/// It recognises a curated vocabulary of technical skills, tools and soft
/// skills (with Vietnamese and English aliases) so the ATS scorer works
/// without network access or AI quota.
abstract final class JdKeywordExtractor {
  /// Canonical keyword -> aliases (lowercase) that count as a mention.
  static const Map<String, List<String>> vocabulary = {
    // Mobile
    'Flutter': ['flutter'],
    'Dart': ['dart'],
    'Kotlin': ['kotlin'],
    'Swift': ['swift'],
    'Android': ['android'],
    'iOS': ['ios'],
    'React Native': ['react native'],
    'Riverpod': ['riverpod'],
    'BLoC': ['bloc'],
    'Jetpack Compose': ['jetpack compose', 'compose'],
    'SQLite': ['sqlite', 'drift', 'room'],
    'Firebase': ['firebase', 'fcm'],
    // Web
    'JavaScript': ['javascript', 'js', 'es6'],
    'TypeScript': ['typescript', 'ts'],
    'React': ['react', 'react.js', 'reactjs'],
    'Next.js': ['next.js', 'nextjs'],
    'Vue.js': ['vue', 'vue.js', 'nuxt'],
    'Angular': ['angular'],
    'HTML/CSS': ['html', 'css', 'scss', 'sass'],
    'Tailwind CSS': ['tailwind'],
    'Redux': ['redux', 'zustand'],
    'Responsive Design': ['responsive'],
    // Backend & data
    'Node.js': ['node.js', 'nodejs', 'express', 'nestjs'],
    'Python': ['python', 'django', 'fastapi', 'flask'],
    'Java': ['java', 'spring', 'spring boot'],
    'C#/.NET': ['c#', '.net', 'asp.net'],
    'Go': ['golang'],
    'PHP': ['php', 'laravel'],
    'SQL': ['sql', 'postgresql', 'postgres', 'mysql', 'sql server'],
    'NoSQL': ['mongodb', 'nosql', 'dynamodb'],
    'Redis': ['redis'],
    'REST API': ['rest', 'restful', 'api'],
    'GraphQL': ['graphql'],
    'Microservices': ['microservice', 'microservices'],
    'Docker': ['docker', 'container'],
    'Kubernetes': ['kubernetes', 'k8s'],
    'AWS': ['aws', 'amazon web services'],
    'Azure': ['azure'],
    'GCP': ['gcp', 'google cloud'],
    'Supabase': ['supabase'],
    'CI/CD': ['ci/cd', 'cicd', 'github actions', 'gitlab ci', 'jenkins'],
    'Git': ['git', 'github', 'gitlab'],
    'Linux': ['linux', 'ubuntu'],
    'Unit Test': ['unit test', 'testing', 'jest', 'junit', 'tdd'],
    'Clean Architecture': ['clean architecture', 'solid', 'design pattern'],
    'OOP': ['oop', 'hướng đối tượng', 'object-oriented'],
    'Data Structures': [
      'data structure',
      'cấu trúc dữ liệu',
      'thuật toán',
      'algorithm',
    ],
    'Machine Learning': ['machine learning', 'ml', 'học máy'],
    'Deep Learning': ['deep learning', 'pytorch', 'tensorflow'],
    'LLM': ['llm', 'prompt engineering', 'genai', 'generative ai'],
    'Power BI': ['power bi', 'powerbi', 'tableau'],
    'Excel': ['excel'],
    'Figma': ['figma', 'ui/ux', 'ux'],
    'Agile/Scrum': ['agile', 'scrum', 'kanban', 'jira'],
    // Business
    'Digital Marketing': ['digital marketing', 'seo', 'sem', 'facebook ads'],
    'Content Marketing': ['content', 'copywriting'],
    'Bán hàng': ['sales', 'bán hàng', 'kinh doanh'],
    'CRM': ['crm', 'salesforce', 'hubspot'],
    'Kế toán': ['kế toán', 'accounting', 'misa'],
    // Soft skills & languages
    'Tiếng Anh': ['english', 'tiếng anh', 'toeic', 'ielts'],
    'Tiếng Nhật': ['japanese', 'tiếng nhật', 'jlpt'],
    'Làm việc nhóm': ['teamwork', 'làm việc nhóm', 'team player'],
    'Giao tiếp': ['communication', 'giao tiếp'],
    'Giải quyết vấn đề': ['problem solving', 'giải quyết vấn đề'],
    'Tự học': ['self-learning', 'tự học', 'ham học hỏi'],
    'Lãnh đạo': ['leadership', 'lãnh đạo', 'team lead'],
    'Quản lý thời gian': ['time management', 'quản lý thời gian'],
  };

  /// Returns canonical keywords mentioned in [jobDescription], in vocabulary
  /// order. Short aliases are matched as whole words to avoid false hits
  /// (e.g. "ts" inside "results").
  static List<String> extract(String jobDescription) {
    final text = ' ${jobDescription.toLowerCase()} ';
    if (text.trim().isEmpty) return const [];

    final found = <String>[];
    vocabulary.forEach((keyword, aliases) {
      final hit = aliases.any((alias) => _mentions(text, alias));
      if (hit) found.add(keyword);
    });
    return List.unmodifiable(found);
  }

  /// Aliases a CV can use to satisfy [keyword] (used for scoring).
  static List<String> aliasesFor(String keyword) =>
      vocabulary[keyword] ?? [keyword.toLowerCase()];

  static bool _mentions(String text, String alias) {
    final escaped = RegExp.escape(alias);
    final pattern = RegExp(
      '(^|[^a-z0-9à-ỹđ+#.])$escaped(?=\$|[^a-z0-9à-ỹđ+#])',
      caseSensitive: false,
      unicode: true,
    );
    return pattern.hasMatch(text);
  }

  /// Whether [corpus] (already lowercase) mentions [keyword] or an alias.
  static bool corpusMentions(String corpus, String keyword) {
    final text = ' $corpus ';
    if (_mentions(text, keyword.toLowerCase())) return true;
    return aliasesFor(keyword).any((alias) => _mentions(text, alias));
  }
}
