import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class EditorTypographyToolbar extends StatelessWidget {
  const EditorTypographyToolbar({
    super.key,
    required this.currentScale,
    required this.language,
    required this.onScaleChanged,
    this.textController,
    this.onOpenStarterSamples,
    this.onOpenSectionReorder,
  });

  final double currentScale;
  final String language;
  final ValueChanged<double> onScaleChanged;
  final TextEditingController? textController;
  final VoidCallback? onOpenStarterSamples;
  final VoidCallback? onOpenSectionReorder;

  bool get _isEn => language == 'en';

  void _insertFormatting(String prefix, String suffix) {
    if (textController == null) return;
    final controller = textController!;
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid || selection.isCollapsed) {
      final insertPos = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(insertPos, insertPos, '$prefix$suffix');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: insertPos + prefix.length),
      );
    } else {
      final selected = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selected$suffix',
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start + prefix.length,
          extentOffset: selection.start + prefix.length + selected.length,
        ),
      );
    }
  }

  void _insertBullet() {
    if (textController == null) return;
    final controller = textController!;
    final text = controller.text;
    final selection = controller.selection;
    final insertPos = selection.isValid ? selection.start : text.length;
    final prefix = (insertPos > 0 && !text.endsWith('\n')) ? '\n• ' : '• ';
    final newText = text.replaceRange(insertPos, insertPos, prefix);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertPos + prefix.length),
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    double tempScale = currentScale;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final percent = (tempScale * 100).round();
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.brandIndigo.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.format_size_rounded,
                      color: AppTheme.brandIndigo,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isEn ? 'Adjust Text Scale' : 'Chỉnh cỡ chữ CV',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isEn
                        ? 'Scale fonts up or down to fill or fit your A4 resume sheet cleanly.'
                        : 'Phóng to hoặc thu nhỏ chữ để CV vừa vặn trang giấy A4 mà không bị trống.',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: tempScale > 0.75
                            ? () {
                                setDialogState(() {
                                  tempScale = (tempScale - 0.05).clamp(0.75, 1.40);
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: AppTheme.brandIndigo,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.brandIndigo.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandIndigo,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: tempScale < 1.40
                            ? () {
                                setDialogState(() {
                                  tempScale = (tempScale + 0.05).clamp(0.75, 1.40);
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: AppTheme.brandIndigo,
                      ),
                    ],
                  ),
                  Slider(
                    value: tempScale,
                    min: 0.75,
                    max: 1.40,
                    divisions: 13,
                    activeColor: AppTheme.brandIndigo,
                    label: '$percent%',
                    onChanged: (val) {
                      setDialogState(() => tempScale = val);
                    },
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      _presetChip(context, setDialogState, 0.85, _isEn ? '85% Compact' : '85% Gọn', tempScale, (s) => tempScale = s),
                      _presetChip(context, setDialogState, 1.0, _isEn ? '100% Standard' : '100% Chuẩn', tempScale, (s) => tempScale = s),
                      _presetChip(context, setDialogState, 1.15, _isEn ? '115% Roomy' : '115% Thoáng', tempScale, (s) => tempScale = s),
                      _presetChip(context, setDialogState, 1.30, _isEn ? '130% Large' : '130% Lớn', tempScale, (s) => tempScale = s),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(_isEn ? 'Cancel' : 'Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onScaleChanged(tempScale);
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandIndigo,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isEn ? 'Apply' : 'Áp dụng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _presetChip(
    BuildContext context,
    StateSetter setDialogState,
    double value,
    String label,
    double current,
    ValueChanged<double> onSelect,
  ) {
    final isSelected = (current - value).abs() < 0.02;

    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) {
        setDialogState(() {
          onSelect(value);
        });
      },
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = (currentScale * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reorder sections button
            if (onOpenSectionReorder != null)
              ActionChip(
                avatar: const Icon(Icons.swap_vert_rounded, size: 16, color: AppTheme.brandIndigo),
                label: Text(
                  _isEn ? 'Reorder' : 'Sắp xếp mục',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: onOpenSectionReorder,
                backgroundColor: AppTheme.brandIndigo.withAlpha(15),
                side: BorderSide(color: AppTheme.brandIndigo.withAlpha(50)),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            const SizedBox(width: 6),
            // Starter samples button
            if (onOpenStarterSamples != null)
              ActionChip(
                avatar: const Icon(Icons.lightbulb_rounded, size: 16, color: Colors.amber),
                label: Text(
                  _isEn ? 'Starter Samples' : 'Mẫu gợi ý',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: onOpenStarterSamples,
                backgroundColor: Colors.amber.shade50,
                side: BorderSide(color: Colors.amber.shade200),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            const SizedBox(width: 6),
            // Font Scale pill button
            ActionChip(
              avatar: const Icon(Icons.format_size_rounded, size: 16, color: AppTheme.brandIndigo),
              label: Text(
                '$percent%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showFontSizeDialog(context),
              backgroundColor: Colors.grey.shade100,
              side: BorderSide(color: Colors.grey.shade300),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              height: 20,
              child: VerticalDivider(width: 1, thickness: 1),
            ),
            const SizedBox(width: 4),
            // Text formatting actions (Bold, Bullet, Link)
            if (textController != null) ...[
              IconButton(
                icon: const Icon(Icons.format_bold_rounded, size: 18),
                tooltip: _isEn ? 'Bold (**text**)' : 'In đậm (**chữ**)',
                onPressed: () => _insertFormatting('**', '**'),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.format_list_bulleted_rounded, size: 18),
                tooltip: _isEn ? 'Bullet point (• )' : 'Gạch đầu dòng (• )',
                onPressed: _insertBullet,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.link_rounded, size: 18),
                tooltip: _isEn ? 'Link ([text](url))' : 'Chèn link ([Tên](link))',
                onPressed: () => _insertFormatting('[', '](https://...)'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
