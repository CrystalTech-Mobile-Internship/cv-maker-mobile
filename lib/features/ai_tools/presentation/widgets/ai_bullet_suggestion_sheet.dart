import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../../../core/widgets/app_sheet.dart';

/// Before/after comparison for AI-rewritten bullets. Returns the bullets the
/// user chose to keep, or null when cancelled.
Future<List<String>?> showAiBulletSuggestionSheet(
  BuildContext context, {
  required List<String> original,
  required AiBulletSuggestion suggestion,
}) {
  return showAppSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) =>
        _AiBulletSuggestionSheet(original: original, suggestion: suggestion),
  );
}

class _AiBulletSuggestionSheet extends StatefulWidget {
  const _AiBulletSuggestionSheet({
    required this.original,
    required this.suggestion,
  });

  final List<String> original;
  final AiBulletSuggestion suggestion;

  @override
  State<_AiBulletSuggestionSheet> createState() =>
      _AiBulletSuggestionSheetState();
}

class _AiBulletSuggestionSheetState extends State<_AiBulletSuggestionSheet> {
  late final List<TextEditingController> _controllers = [
    for (final bullet in widget.suggestion.bullets)
      TextEditingController(text: bullet),
  ];
  late final List<bool> _selected = List.filled(_controllers.length, true);

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPlaceholder = _controllers.any(
      (c) => RegExp(r'\[[^\]]+\]').hasMatch(c.text),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          const Text(
            'Gợi ý viết lại',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chọn và chỉnh lại từng dòng trước khi áp dụng. Bản cũ được giữ nếu bạn hủy.',
            style: TextStyle(color: AppTheme.mutedText),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Bản hiện tại',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            children: [
              for (final line in widget.original)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $line',
                      style: const TextStyle(color: AppTheme.mutedText),
                    ),
                  ),
                ),
            ],
          ),
          for (var i = 0; i < _controllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _selected[i],
                    onChanged: (value) =>
                        setState(() => _selected[i] = value ?? false),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controllers[i],
                      minLines: 1,
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          if (hasPlaceholder)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.amberSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Thay các chỗ trong [ngoặc vuông] bằng số liệu thật của bạn, hoặc xóa đi nếu không có.',
              ),
            ),
          for (final tip in widget.suggestion.tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: AppTheme.mutedText,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(color: AppTheme.mutedText),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Giữ bản cũ'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('apply-ai-bullets'),
                  onPressed: _selected.contains(true)
                      ? () => Navigator.pop(context, [
                          for (var i = 0; i < _controllers.length; i++)
                            if (_selected[i] &&
                                _controllers[i].text.trim().isNotEmpty)
                              _controllers[i].text.trim(),
                        ])
                      : null,
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
