import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/i18n/app_language.dart';

/// Editable AI cover letter with a copy action.
Future<void> showCoverLetterSheet(BuildContext context, String letter) {
  final controller = TextEditingController(text: letter);
  return showAppSheet<void>(
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
          Text(
            tr('Thư xin việc', 'Cover letter'),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Đọc lại, sửa tên người nhận và thông tin chưa chính xác trước khi gửi.',
              'Read it through and fix the recipient name and any wrong details before sending.',
            ),
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
                  SnackBar(
                    content: Text(
                      tr('Đã sao chép thư xin việc.', 'Cover letter copied.'),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(tr('Sao chép', 'Copy')),
          ),
        ],
      ),
    ),
  ).whenComplete(controller.dispose);
}
