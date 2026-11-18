import '../models/skill_model.dart';

/// One printed skills line, such as `Frontend: React, HTML/CSS`.
final class CvSkillLine {
  const CvSkillLine(this.label, this.skills);

  final String label;
  final List<String> skills;

  String get text => skills.join(', ');
}

/// Splits technical skills into readable groups for the CV.
///
/// A group typed by the user always wins. Otherwise common technologies are
/// placed by name, so older CVs read well without any extra work.
abstract final class CvSkillGrouper {
  static const languages = 'languages';
  static const frontend = 'frontend';
  static const backend = 'backend';
  static const mobile = 'mobile';
  static const database = 'database';
  static const devops = 'devops';
  static const tools = 'tools';
  static const _other = 'other';

  static const _order = [
    languages,
    frontend,
    backend,
    mobile,
    database,
    devops,
    tools,
  ];

  static const _labels = {
    languages: ('Ngôn ngữ', 'Languages'),
    frontend: ('Frontend', 'Frontend'),
    backend: ('Backend', 'Backend'),
    mobile: ('Mobile', 'Mobile'),
    database: ('Cơ sở dữ liệu', 'Databases'),
    devops: ('DevOps & Cloud', 'DevOps & Cloud'),
    tools: ('Công cụ', 'Tools'),
    _other: ('Khác', 'Other'),
  };

  static const _exact = <String, String>{
    // Languages
    'java': languages, 'javascript': languages, 'js': languages,
    'typescript': languages, 'ts': languages, 'python': languages,
    'c': languages, 'c++': languages, 'c#': languages, 'go': languages,
    'golang': languages, 'kotlin': languages, 'swift': languages,
    'dart': languages, 'php': languages, 'ruby': languages,
    'rust': languages, 'scala': languages, 'r': languages,
    // Frontend
    'html': frontend, 'css': frontend, 'html/css': frontend,
    'html5': frontend, 'css3': frontend, 'react': frontend,
    'reactjs': frontend, 'react.js': frontend, 'next.js': frontend,
    'nextjs': frontend, 'vue': frontend, 'vue.js': frontend,
    'vuejs': frontend, 'nuxt': frontend, 'angular': frontend,
    'svelte': frontend, 'tailwind': frontend, 'tailwind css': frontend,
    'tailwindcss': frontend, 'sass': frontend, 'scss': frontend,
    'bootstrap': frontend, 'redux': frontend, 'jquery': frontend,
    'vite': frontend, 'webpack': frontend, 'material ui': frontend,
    // Backend
    'node.js': backend, 'nodejs': backend, 'node': backend,
    'express': backend, 'express.js': backend, 'nestjs': backend,
    'fastapi': backend, 'django': backend, 'flask': backend,
    'laravel': backend, '.net': backend, 'asp.net': backend,
    'asp.net core': backend, 'hibernate': backend, 'jpa': backend,
    'restful api': backend, 'restful apis': backend, 'rest api': backend,
    'rest': backend, 'graphql': backend, 'grpc': backend, 'jwt': backend,
    'oauth2': backend, 'websocket': backend, 'websockets': backend,
    'webrtc': backend, 'socket.io': backend, 'microservices': backend,
    'kafka': backend, 'rabbitmq': backend,
    // Mobile
    'react native': mobile, 'flutter': mobile, 'android': mobile,
    'ios': mobile, 'swiftui': mobile, 'jetpack compose': mobile,
    'expo': mobile,
    // Databases
    'sql': database, 'mysql': database, 'postgresql': database,
    'postgres': database, 'mongodb': database, 'redis': database,
    'sqlite': database, 'oracle': database, 'sql server': database,
    'mariadb': database, 'firebase': database, 'supabase': database,
    'elasticsearch': database, 'dynamodb': database,
    // DevOps & cloud
    'docker': devops, 'kubernetes': devops, 'k8s': devops, 'aws': devops,
    'azure': devops, 'gcp': devops, 'google cloud': devops,
    'cloudflare': devops, 'ci/cd': devops, 'github actions': devops,
    'jenkins': devops, 'nginx': devops, 'linux': devops,
    'vercel': devops, 'terraform': devops, 'heroku': devops,
    // Tools
    'git': tools, 'github': tools, 'gitlab': tools, 'git/github': tools,
    'jira': tools, 'figma': tools, 'postman': tools, 'swagger': tools,
    'postman/swagger': tools, 'trello': tools, 'notion': tools,
    'vs code': tools, 'intellij': tools, 'confluence': tools,
  };

  /// Prefixes for names that come in many variants, e.g. `Spring Boot`.
  static const _prefixes = <(String, String)>[
    ('react native', mobile),
    ('spring', backend),
    ('aws', devops),
    ('azure', devops),
    ('cloudflare', devops),
    ('google cloud', devops),
    ('github', tools),
    ('git', tools),
  ];

  /// Group key guessed from the skill name, or null when unknown.
  static String? guess(String name) {
    final key = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (key.isEmpty) return null;
    final exact = _exact[key];
    if (exact != null) return exact;
    for (final (prefix, group) in _prefixes) {
      if (key.startsWith(prefix)) return group;
    }
    return null;
  }

  /// Label to show for a guessed group key.
  static String label(String key, {required bool isEn}) {
    final pair = _labels[key];
    if (pair == null) return key;
    return isEn ? pair.$2 : pair.$1;
  }

  /// Heading a technical skill falls under in the editor and the CV.
  static String labelFor(SkillModel skill, {required bool isEn}) {
    final custom = skill.group.trim();
    final key = custom.isNotEmpty
        ? _keyForLabel(custom)
        : (guess(skill.name) ?? _other);
    return label(key, isEn: isEn);
  }

  /// Suggested group names for the editor, in display order.
  static List<String> suggestions({required bool isEn}) => [
    for (final key in _order) label(key, isEn: isEn),
  ];

  /// Printed lines: grouped technical skills, then soft skills.
  static List<CvSkillLine> lines(
    List<SkillModel> skills, {
    required bool isEn,
  }) {
    final hard = skills
        .where((s) => s.category == SkillCategory.hard && s.name.isNotEmpty)
        .toList();
    final soft = skills
        .where((s) => s.category == SkillCategory.soft && s.name.isNotEmpty)
        .map((s) => s.name)
        .toList();

    // Keys are either a known group key or a custom label typed by the user.
    final groups = <String, List<String>>{};
    for (final skill in hard) {
      final custom = skill.group.trim();
      final key = custom.isNotEmpty
          ? _keyForLabel(custom)
          : (guess(skill.name) ?? _other);
      groups.putIfAbsent(key, () => []).add(skill.name);
    }

    final result = <CvSkillLine>[];
    final onlyUnknown = groups.length == 1 && groups.containsKey(_other);
    if (onlyUnknown) {
      // Nothing recognised: keep the single classic line.
      result.add(
        CvSkillLine(
          isEn ? 'Technical skills' : 'Kỹ năng chuyên môn',
          groups[_other]!,
        ),
      );
    } else {
      for (final key in _order) {
        final names = groups.remove(key);
        if (names != null) {
          result.add(CvSkillLine(label(key, isEn: isEn), names));
        }
      }
      final other = groups.remove(_other);
      for (final entry in groups.entries) {
        result.add(CvSkillLine(entry.key, entry.value));
      }
      if (other != null) {
        result.add(CvSkillLine(label(_other, isEn: isEn), other));
      }
    }

    if (soft.isNotEmpty) {
      result.add(CvSkillLine(isEn ? 'Soft skills' : 'Kỹ năng mềm', soft));
    }
    return result;
  }

  /// Maps a typed label back to a known key so `backend` and `Backend`
  /// share one line, while new labels stay as typed.
  static String _keyForLabel(String typed) {
    final lower = typed.toLowerCase();
    for (final entry in _labels.entries) {
      if (entry.key == _other) continue;
      if (entry.value.$1.toLowerCase() == lower ||
          entry.value.$2.toLowerCase() == lower) {
        return entry.key;
      }
    }
    return typed;
  }
}
