import 'package:flutter/material.dart';

Future<bool> showSummaryPolishPreviewSheet({
  required BuildContext context,
  required String original,
  required String suggested,
  required String provider,
  required bool isEnglish,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEnglish ? 'Review AI suggestion' : 'Xem trước gợi ý AI',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isEnglish ? 'Provider' : 'Nguồn xử lý'}: $provider',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  _SummaryCard(
                    title: isEnglish ? 'Original' : 'Nội dung gốc',
                    content: original,
                    muted: true,
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    title: isEnglish ? 'AI suggestion' : 'Nội dung đề xuất',
                    content: suggested,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    key: const Key('apply-ai-summary'),
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      isEnglish ? 'Apply suggestion' : 'Áp dụng đề xuất',
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(isEnglish ? 'Keep original' : 'Giữ bản gốc'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ) ??
      false;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.content,
    this.muted = false,
  });

  final String title;
  final String content;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF8FAFC) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: muted ? const Color(0xFFE2E8F0) : const Color(0xFFC7D2FE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SelectableText(content),
        ],
      ),
    );
  }
}
