import '../models/models.dart';

/// Lightweight description of one entry inside a CV section, used by the
/// drag-and-drop item ordering UI.
class CvItemSummary {
  const CvItemSummary({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.sortDate,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Most relevant date for "newest first" sorting (current roles first).
  final DateTime? sortDate;
}

/// Reorders the entries inside a section (experience, projects, education,
/// skills, certifications) without touching their content.
abstract final class CvItemOrderService {
  static const reorderableSections = {
    'experience',
    'projects',
    'education',
    'skills',
    'certifications',
  };

  static final _farFuture = DateTime.utc(9999);

  static String _period(DateTime? start, DateTime? end, bool current) {
    String fmt(DateTime? d) =>
        d == null ? '' : '${d.month.toString().padLeft(2, '0')}/${d.year}';
    if (start == null && end == null && !current) return '';
    return '${fmt(start)} – ${current ? 'nay' : fmt(end)}';
  }

  static List<CvItemSummary> itemsFor(CvModel cv, String section) {
    switch (section) {
      case 'experience':
        return [
          for (final e in cv.experiences)
            CvItemSummary(
              id: e.id,
              title: e.jobTitle.isEmpty ? '(Chưa có chức danh)' : e.jobTitle,
              subtitle: [
                e.company,
                _period(e.startDate, e.endDate, e.isCurrent),
              ].where((s) => s.isNotEmpty).join(' · '),
              sortDate: e.isCurrent ? _farFuture : (e.endDate ?? e.startDate),
            ),
        ];
      case 'projects':
        return [
          for (final p in cv.projects)
            CvItemSummary(
              id: p.id,
              title: p.name.isEmpty ? '(Chưa có tên dự án)' : p.name,
              subtitle: [
                p.role,
                _period(p.startDate, p.endDate, false),
              ].where((s) => s.isNotEmpty).join(' · '),
              sortDate: p.endDate ?? p.startDate,
            ),
        ];
      case 'education':
        return [
          for (final e in cv.educations)
            CvItemSummary(
              id: e.id,
              title: e.institution.isEmpty ? '(Chưa có trường)' : e.institution,
              subtitle: [
                '${e.degree} ${e.fieldOfStudy}'.trim(),
                _period(e.startDate, e.endDate, e.isCurrent),
              ].where((s) => s.isNotEmpty).join(' · '),
              sortDate: e.isCurrent ? _farFuture : (e.endDate ?? e.startDate),
            ),
        ];
      case 'skills':
        return [
          for (final s in cv.skills)
            CvItemSummary(
              id: s.id,
              title: s.name,
              subtitle: s.category == SkillCategory.soft
                  ? 'Kỹ năng mềm'
                  : 'Kỹ năng chuyên môn',
            ),
        ];
      case 'certifications':
        return [
          for (final c in cv.certifications)
            CvItemSummary(
              id: c.id,
              title: c.name,
              subtitle: [
                c.issuer,
                c.score ?? '',
              ].where((s) => s.isNotEmpty).join(' · '),
              sortDate: c.issueDate,
            ),
        ];
      default:
        return const [];
    }
  }

  /// Returns [cv] with the section's entries arranged as [orderedIds].
  /// Unknown ids are ignored and missing entries are appended, so no entry
  /// can be lost by a stale order.
  static CvModel reorder(CvModel cv, String section, List<String> orderedIds) {
    List<T> arrange<T>(List<T> items, String Function(T) idOf) {
      final byId = {for (final item in items) idOf(item): item};
      final result = <T>[
        for (final id in orderedIds)
          if (byId.containsKey(id)) byId.remove(id) as T,
      ];
      result.addAll(items.where((item) => byId.containsKey(idOf(item))));
      return result;
    }

    switch (section) {
      case 'experience':
        return cv.copyWith(experiences: arrange(cv.experiences, (e) => e.id));
      case 'projects':
        return cv.copyWith(projects: arrange(cv.projects, (p) => p.id));
      case 'education':
        return cv.copyWith(educations: arrange(cv.educations, (e) => e.id));
      case 'skills':
        return cv.copyWith(skills: arrange(cv.skills, (s) => s.id));
      case 'certifications':
        return cv.copyWith(
          certifications: arrange(cv.certifications, (c) => c.id),
        );
      default:
        return cv;
    }
  }

  /// Ids sorted newest first (current entries on top, undated last). Stable
  /// for equal dates.
  static List<String> newestFirst(List<CvItemSummary> items) {
    final indexed = items.asMap().entries.toList();
    indexed.sort((a, b) {
      final da = a.value.sortDate;
      final db = b.value.sortDate;
      if (da == null && db == null) return a.key.compareTo(b.key);
      if (da == null) return 1;
      if (db == null) return -1;
      final byDate = db.compareTo(da);
      return byDate != 0 ? byDate : a.key.compareTo(b.key);
    });
    return [for (final entry in indexed) entry.value.id];
  }
}
