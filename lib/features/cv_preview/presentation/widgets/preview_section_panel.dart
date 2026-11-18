import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/cv_section_definition.dart';
import '../../../cv_editor/domain/services/cv_item_order_service.dart';

/// Desktop side panel next to the print view: drag sections to reorder,
/// show or hide them, and pick one to work on.
class PreviewSectionPanel extends StatelessWidget {
  const PreviewSectionPanel({
    super.key,
    required this.cv,
    required this.selected,
    required this.onSelect,
    required this.onVisibleOrderChanged,
    required this.onToggleVisibility,
    required this.onReorderItems,
  });

  final CvModel cv;
  final String? selected;
  final ValueChanged<String> onSelect;

  /// New order of the sections shown on the page.
  final ValueChanged<List<String>> onVisibleOrderChanged;
  final ValueChanged<String> onToggleVisibility;
  final ValueChanged<String> onReorderItems;

  bool get _en => cv.language == 'en';

  @override
  Widget build(BuildContext context) {
    final visible = cv.visibleSectionOrder;
    final hidden = cv.effectiveSectionOrder
        .where((id) => !cv.isSectionVisible(id))
        .toList();

    return Material(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Heading(
              _en ? 'On the page' : 'Trên trang',
              hint: _en
                  ? 'Drag to reorder · Alt + ↑/↓'
                  : 'Kéo để đổi thứ tự · Alt + ↑/↓',
            ),
          ),
          SliverReorderableList(
            itemCount: visible.length,
            onReorder: (from, to) {
              final order = [...visible];
              final item = order.removeAt(from);
              order.insert(to > from ? to - 1 : to, item);
              onVisibleOrderChanged(order);
            },
            itemBuilder: (context, index) {
              final id = visible[index];
              return ReorderableDragStartListener(
                key: ValueKey('panel-section-$id'),
                index: index,
                child: _SectionRow(
                  cv: cv,
                  id: id,
                  isVisible: true,
                  isSelected: selected == id,
                  onTap: () => onSelect(id),
                  onToggle: () => onToggleVisibility(id),
                  onReorderItems: () => onReorderItems(id),
                ),
              );
            },
          ),
          if (hidden.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _Heading(
                _en ? 'Hidden' : 'Đang ẩn',
                hint: _en ? 'Not printed' : 'Không in ra',
              ),
            ),
            SliverList.list(
              children: [
                for (final id in hidden)
                  _SectionRow(
                    key: ValueKey('panel-hidden-$id'),
                    cv: cv,
                    id: id,
                    isVisible: false,
                    isSelected: selected == id,
                    onTap: () => onSelect(id),
                    onToggle: () => onToggleVisibility(id),
                    onReorderItems: () => onReorderItems(id),
                  ),
              ],
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, {required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppTheme.mutedText),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    super.key,
    required this.cv,
    required this.id,
    required this.isVisible,
    required this.isSelected,
    required this.onTap,
    required this.onToggle,
    required this.onReorderItems,
  });

  final CvModel cv;
  final String id;
  final bool isVisible;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onReorderItems;

  @override
  Widget build(BuildContext context) {
    final en = cv.language == 'en';
    final definition = CvSectionDefinition.findById(id);
    final itemCount = CvItemOrderService.itemsFor(cv, id).length;
    final color = isVisible ? AppTheme.primaryNavy : AppTheme.mutedText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? AppTheme.indigoSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 2, 2),
            child: Row(
              children: [
                Icon(
                  isVisible
                      ? Icons.drag_indicator_rounded
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppTheme.mutedText,
                ),
                const SizedBox(width: 6),
                Icon(
                  definition?.icon ?? Icons.notes_rounded,
                  size: 18,
                  color: isSelected ? AppTheme.brandIndigo : color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    definition?.title(cv.language) ?? id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.brandIndigo : color,
                    ),
                  ),
                ),
                if (itemCount > 1)
                  IconButton(
                    tooltip: en
                        ? 'Reorder entries ($itemCount)'
                        : 'Sắp xếp $itemCount mục con',
                    visualDensity: VisualDensity.compact,
                    onPressed: onReorderItems,
                    icon: const Icon(Icons.low_priority_rounded, size: 18),
                  ),
                IconButton(
                  key: ValueKey('panel-toggle-$id'),
                  tooltip: isVisible
                      ? (en ? 'Hide from print' : 'Ẩn khỏi bản in')
                      : (en ? 'Show on page' : 'Hiện lên trang'),
                  visualDensity: VisualDensity.compact,
                  onPressed: onToggle,
                  icon: Icon(
                    isVisible
                        ? Icons.visibility_outlined
                        : Icons.add_circle_outline_rounded,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
