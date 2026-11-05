import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/cv_section_definition.dart';

/// Interactive modular section drag-and-drop workspace for the CV preview screen.
///
/// Allows candidates to visualize all sections as tactile cards, drag-and-drop
/// to rearrange the CV layout, inspect preview snippets, and jump to edit.
class CvInteractiveSectionReorder extends StatelessWidget {
  const CvInteractiveSectionReorder({
    super.key,
    required this.cv,
    required this.language,
    required this.onOrderChanged,
    this.onEditSection,
    this.onResetToDefault,
    this.onSwitchToPdfView,
  });

  final CvModel cv;
  final String language;
  final ValueChanged<List<String>> onOrderChanged;
  final ValueChanged<String>? onEditSection;
  final VoidCallback? onResetToDefault;
  final VoidCallback? onSwitchToPdfView;

  bool get _isEn => language == 'en';

  void _moveItem(int oldIndex, int newIndex) {
    final list = List<String>.from(cv.effectiveSectionOrder);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    onOrderChanged(list);
  }

  void _stepItem(int index, int delta) {
    final target = index + delta;
    final list = List<String>.from(cv.effectiveSectionOrder);
    if (target < 0 || target >= list.length) return;
    final item = list.removeAt(index);
    list.insert(target, item);
    onOrderChanged(list);
  }

  Widget _buildSnippet(String key) {
    switch (key) {
      case 'summary':
        final text = cv.summary.trim();
        return text.isNotEmpty
            ? Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
              )
            : Text(
                _isEn ? 'No summary added yet.' : 'Chưa nhập tóm tắt.',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.mutedText),
              );

      case 'experience':
        if (cv.experiences.isEmpty) {
          return Text(
            _isEn ? 'No work experience yet.' : 'Chưa có kinh nghiệm.',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.mutedText),
          );
        }
        final first = cv.experiences.first;
        return Text(
          '${first.jobTitle} • ${first.company} (${cv.experiences.length} ${_isEn ? 'items' : 'mục'})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedText),
        );

      case 'projects':
        if (cv.projects.isEmpty) {
          return Text(
            _isEn ? 'No projects added.' : 'Chưa có dự án.',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.mutedText),
          );
        }
        final p = cv.projects.first;
        return Text(
          '${p.name} • ${p.role.isNotEmpty ? p.role : (_isEn ? 'Project' : 'Dự án')} (${cv.projects.length} ${_isEn ? 'projects' : 'dự án'})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedText),
        );

      case 'skills':
        if (cv.skills.isEmpty) {
          return Text(
            _isEn ? 'No skills listed.' : 'Chưa liệt kê kỹ năng.',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.mutedText),
          );
        }
        final names = cv.skills.take(4).map((s) => s.name).join(', ');
        return Text(
          '$names... (${cv.skills.length} ${_isEn ? 'skills' : 'kỹ năng'})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
        );

      case 'education':
        if (cv.educations.isEmpty) {
          return Text(
            _isEn ? 'No education added.' : 'Chưa nhập học vấn.',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.mutedText),
          );
        }
        final e = cv.educations.first;
        return Text(
          '${e.degree.isNotEmpty ? '${e.degree} • ' : ''}${e.institution}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedText),
        );

      case 'certifications':
        if (cv.certifications.isEmpty) {
          return Text(
            _isEn ? 'No certifications.' : 'Chưa có chứng chỉ.',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.mutedText),
          );
        }
        final c = cv.certifications.first;
        return Text(
          '${c.name} (${c.issuer})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedText),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = cv.effectiveSectionOrder;

    return Column(
      children: [
        // Helper instruction & Quick Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.drag_indicator_rounded, size: 20, color: AppTheme.brandIndigo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isEn
                            ? 'Drag cards to reorder your A4 layout in real-time'
                            : 'Kéo thả thẻ để sắp xếp thứ tự trên bản A4',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primarySlate,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onResetToDefault != null)
                TextButton.icon(
                  onPressed: onResetToDefault,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: Text(_isEn ? 'Default' : 'Mặc định', style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppTheme.mutedText,
                  ),
                ),
            ],
          ),
        ),

        // Reorderable Card List
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: sections.length,
            onReorder: _moveItem,
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 6,
                color: Colors.transparent,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final key = sections[index];
              final def = CvSectionDefinition.findById(key) ??
                  const CvSectionDefinition(
                    id: '',
                    titleVi: '',
                    titleEn: '',
                    icon: Icons.article_outlined,
                    hintVi: '',
                    hintEn: '',
                  );
              final isFirst = index == 0;
              final isLast = index == sections.length - 1;

              return Card(
                key: ValueKey('preview-section-$key'),
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Order Badge
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.brandIndigo.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandIndigo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Icon
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(def.icon, size: 20, color: AppTheme.primarySlate),
                      ),
                      const SizedBox(width: 12),

                      // Section Title & Snippet Preview
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              def.title(_isEn ? "en" : "vi"),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primarySlate,
                              ),
                            ),
                            const SizedBox(height: 3),
                            _buildSnippet(key),
                          ],
                        ),
                      ),

                      // Step Up/Down & Drag Handle
                      IconButton(
                        tooltip: _isEn ? 'Move up' : 'Di chuyển lên',
                        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                        onPressed: isFirst ? null : () => _stepItem(index, -1),
                        visualDensity: VisualDensity.compact,
                        color: AppTheme.mutedText,
                      ),
                      IconButton(
                        tooltip: _isEn ? 'Move down' : 'Di chuyển xuống',
                        icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                        onPressed: isLast ? null : () => _stepItem(index, 1),
                        visualDensity: VisualDensity.compact,
                        color: AppTheme.mutedText,
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.drag_indicator_rounded,
                            size: 22,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
