import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';

/// Editable AI cover letter with a copy action.
Future<void> showCoverLetterSheet(BuildContext context, String letter) {
  final controller = TextEditingController(text: letter);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
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
            'Thư xin việc',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Đọc lại, sửa tên người nhận và thông tin chưa chính xác trước khi gửi.',
            style: TextStyle(color: AppTheme.mutedText),
          ),
          const SizedBox(height: 12),
          TextField(controller: controller, minLines: 12, maxLines: null),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: controller.text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép thư xin việc.')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Sao chép'),
          ),
        ],
      ),
    ),
  ).whenComplete(controller.dispose);
}
