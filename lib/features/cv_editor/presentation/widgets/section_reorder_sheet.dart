import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/cv_section_definition.dart';

class SectionReorderSheet extends StatefulWidget {
  const SectionReorderSheet({
    super.key,
    required this.initialOrder,
    required this.language,
    required this.onOrderChanged,
  });

  final List<String> initialOrder;
  final String language;
  final ValueChanged<List<String>> onOrderChanged;

  static Future<void> show({
    required BuildContext context,
    required List<String> currentOrder,
    required String language,
    required ValueChanged<List<String>> onOrderChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SectionReorderSheet(
        initialOrder: currentOrder,
        language: language,
        onOrderChanged: onOrderChanged,
      ),
    );
  }

  @override
  State<SectionReorderSheet> createState() => _SectionReorderSheetState();
}

class _SectionReorderSheetState extends State<SectionReorderSheet> {
  late List<String> _sections;

  bool get _isEn => widget.language == 'en';

  @override
  void initState() {
    super.initState();
    _sections = List.of(widget.initialOrder);
    // Ensure all known sections are present
    for (final def in CvSectionDefinition.all) {
      if (!_sections.contains(def.id)) {
        _sections.add(def.id);
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _sections.removeAt(oldIndex);
      _sections.insert(newIndex, item);
    });
    widget.onOrderChanged(List.unmodifiable(_sections));
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    _onReorder(index, index - 1);
  }

  void _moveDown(int index) {
    if (index >= _sections.length - 1) return;
    _onReorder(index, index + 2);
  }

  void _resetDefault() {
    setState(() {
      _sections = CvSectionDefinition.all.map((d) => d.id).toList();
    });
    widget.onOrderChanged(List.unmodifiable(_sections));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.brandIndigo.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.swap_vert_rounded,
                      color: AppTheme.brandIndigo,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEn ? 'Reorder CV Sections' : 'Sắp xếp các mục',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isEn
                              ? 'Drag or tap arrows to prioritize sections'
                              : 'Kéo thả hoặc bấm mũi tên để đổi thứ tự xuất hiện',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetDefault,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(_isEn ? 'Reset' : 'Mặc định'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Reorderable List
            Flexible(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shrinkWrap: true,
                itemCount: _sections.length,
                onReorder: _onReorder,
                itemBuilder: (context, index) {
                  final sectionId = _sections[index];
                  final def = CvSectionDefinition.findById(sectionId);
                  final title = def?.title(widget.language) ?? sectionId;
                  final hint = def?.hint(widget.language) ?? '';
                  final icon = def?.icon ?? Icons.view_headline_rounded;

                  return Container(
                    key: ValueKey(sectionId),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: AppTheme.brandIndigo,
                        ),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                      subtitle: Text(
                        hint,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_upward_rounded,
                              size: 18,
                            ),
                            color: index > 0
                                ? AppTheme.brandIndigo
                                : Colors.grey.shade300,
                            onPressed: index > 0 ? () => _moveUp(index) : null,
                            tooltip: _isEn ? 'Move up' : 'Di chuyển lên',
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_downward_rounded,
                              size: 18,
                            ),
                            color: index < _sections.length - 1
                                ? AppTheme.brandIndigo
                                : Colors.grey.shade300,
                            onPressed: index < _sections.length - 1
                                ? () => _moveDown(index)
                                : null,
                            tooltip: _isEn ? 'Move down' : 'Di chuyển xuống',
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                color: Colors.grey,
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
            // Bottom confirmation action
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded),
                label: Text(_isEn ? 'Done & Update CV' : 'Áp dụng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
