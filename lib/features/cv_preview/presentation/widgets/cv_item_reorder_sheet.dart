import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/services/cv_item_order_service.dart';
import '../../../../core/widgets/app_sheet.dart';

/// Drag-and-drop ordering of the entries inside one CV section. Returns the
/// new id order, or null when cancelled.
Future<List<String>?> showCvItemReorderSheet(
  BuildContext context, {
  required String sectionTitle,
  required List<CvItemSummary> items,
  required bool isEnglish,
}) {
  return showAppSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _CvItemReorderSheet(
      sectionTitle: sectionTitle,
      items: items,
      isEnglish: isEnglish,
    ),
  );
}

class _CvItemReorderSheet extends StatefulWidget {
  const _CvItemReorderSheet({
    required this.sectionTitle,
    required this.items,
    required this.isEnglish,
  });

  final String sectionTitle;
  final List<CvItemSummary> items;
  final bool isEnglish;

  @override
  State<_CvItemReorderSheet> createState() => _CvItemReorderSheetState();
}

class _CvItemReorderSheetState extends State<_CvItemReorderSheet> {
  late List<CvItemSummary> _items = List.of(widget.items);

  bool get _en => widget.isEnglish;

  bool get _changed {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id != widget.items[i].id) return true;
    }
    return false;
  }

  bool get _hasDates => _items.any((item) => item.sortDate != null);

  void _sortNewestFirst() {
    final order = CvItemOrderService.newestFirst(_items);
    final byId = {for (final item in _items) item.id: item};
    setState(() => _items = [for (final id in order) byId[id]!]);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sectionTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _en
                              ? 'Drag to change the order on your CV.'
                              : 'Kéo thả để đổi thứ tự hiển thị trên CV.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasDates)
                    TextButton(
                      key: const ValueKey('item-sort-newest'),
                      onPressed: _sortNewestFirst,
                      child: Text(_en ? 'Newest first' : 'Mới nhất lên đầu'),
                    ),
                ],
              ),
            ),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _items.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _items.removeAt(oldIndex);
                    _items.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Container(
                    key: ValueKey('reorder-item-${item.id}'),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.softBorder),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(left: 12, right: 4),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.indigoSurface,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandIndigo,
                          ),
                        ),
                      ),
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: item.subtitle.isEmpty
                          ? null
                          : Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(_en ? 'Cancel' : 'Hủy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('item-reorder-apply'),
                      onPressed: _changed
                          ? () => Navigator.pop(context, [
                              for (final item in _items) item.id,
                            ])
                          : null,
                      child: Text(_en ? 'Apply' : 'Áp dụng'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
