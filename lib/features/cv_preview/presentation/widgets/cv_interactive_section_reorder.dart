import '../../../cv_editor/domain/services/cv_item_order_service.dart';
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
    this.onToggleVisibility,
    this.onReorderItems,
    this.contentCv,
    this.onCheckQuality,
  });

  final CvModel cv;
  final String language;
  final ValueChanged<List<String>> onOrderChanged;
  final ValueChanged<String>? onEditSection;
  final VoidCallback? onResetToDefault;
  final VoidCallback? onSwitchToPdfView;
  final ValueChanged<String>? onToggleVisibility;

  /// Opens item-level ordering for a section (experience, projects...).
  final ValueChanged<String>? onReorderItems;
  final VoidCallback? onCheckQuality;

  /// The user's real CV when [cv] includes sample filler content. Entry
  /// ordering is only offered for real entries.
  final CvModel? contentCv;

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
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.mutedText,
                ),
              );

      case 'experience':
        if (cv.experiences.isEmpty) {
          return Text(
            _isEn ? 'No work experience yet.' : 'Chưa có kinh nghiệm.',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.mutedText,
            ),
          );
        }
        final first = cv.experiences.first;
        return Text(
          '${first.jobTitle} • ${first.company} (${cv.experiences.length} ${_isEn ? 'items' : 'mục'})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedText,
          ),
        );

      case 'projects':
        if (cv.projects.isEmpty) {
          return Text(
            _isEn ? 'No projects added.' : 'Chưa có dự án.',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.mutedText,
            ),
          );
        }
        final p = cv.projects.first;
        return Text(
          '${p.name} • ${p.role.isNotEmpty ? p.role : (_isEn ? 'Project' : 'Dự án')} (${cv.projects.length} ${_isEn ? 'projects' : 'dự án'})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedText,
          ),
        );

      case 'skills':
        if (cv.skills.isEmpty) {
          return Text(
            _isEn ? 'No skills listed.' : 'Chưa liệt kê kỹ năng.',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.mutedText,
            ),
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
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.mutedText,
            ),
          );
        }
        final e = cv.educations.first;
        return Text(
          '${e.degree.isNotEmpty ? '${e.degree} • ' : ''}${e.institution}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedText,
          ),
        );

      case 'certifications':
        if (cv.certifications.isEmpty) {
          return Text(
            _isEn ? 'No certifications.' : 'Chưa có chứng chỉ.',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.mutedText,
            ),
          );
        }
        final c = cv.certifications.first;
        return Text(
          '${c.name} (${c.issuer})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedText,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  int _itemCount(String section) =>
      CvItemOrderService.itemsFor(contentCv ?? cv, section).length;

  bool _canReorderItems(String section) =>
      onReorderItems != null &&
      CvItemOrderService.reorderableSections.contains(section) &&
      _itemCount(section) >= 2;

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
                    const Icon(
                      Icons.drag_indicator_rounded,
                      size: 20,
                      color: AppTheme.brandIndigo,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isEn
                            ? 'Drag cards to reorder your A4 layout in real-time'
                            : 'Kéo thả để đổi thứ tự',
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
              if (onCheckQuality != null)
                TextButton(
                  key: const Key('preview-quality-check-btn'),
                  onPressed: onCheckQuality,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    _isEn ? 'Check' : 'Kiểm tra',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (onResetToDefault != null)
                TextButton.icon(
                  onPressed: onResetToDefault,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: Text(
                    _isEn ? 'Default' : 'Mặc định',
                    style: const TextStyle(fontSize: 12),
                  ),
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
              final def =
                  CvSectionDefinition.findById(key) ??
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
              final isVisible = cv.isSectionVisible(key);
              final showIcon = MediaQuery.sizeOf(context).width >= 440;

              return Card(
                key: ValueKey('preview-section-$key'),
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                color: isVisible ? Colors.white : const Color(0xFFF8FAFC),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Row(
                    children: [
                      if (showIcon) ...[
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            def.icon,
                            size: 18,
                            color: AppTheme.primarySlate,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],

                      // Section Title & Snippet Preview
                      Expanded(
                        child: InkWell(
                          key: Key('reorder-items-$key'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: _canReorderItems(key)
                              ? () => onReorderItems!(key)
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      def.title(_isEn ? "en" : "vi"),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isVisible
                                            ? AppTheme.primarySlate
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (!isVisible) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _isEn ? 'Hidden' : 'Đã ẩn',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              _buildSnippet(key),
                              if (_canReorderItems(key)) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _isEn
                                      ? '${_itemCount(key)} entries · tap to reorder'
                                      : '${_itemCount(key)} mục · chạm để sắp xếp',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.brandIndigo,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Toggle Visibility Button
                      IconButton(
                        key: Key('toggle-visibility-$key'),
                        tooltip: isVisible
                            ? (_isEn ? 'Hide from export' : 'Ẩn khỏi bản in')
                            : (_isEn ? 'Show in export' : 'Hiện trên bản in'),
                        icon: Icon(
                          isVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 19,
                          color: isVisible ? AppTheme.brandIndigo : Colors.grey,
                        ),
                        onPressed: onToggleVisibility == null
                            ? null
                            : () => onToggleVisibility!(key),
                        visualDensity: VisualDensity.compact,
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
                        icon: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 18,
                        ),
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
