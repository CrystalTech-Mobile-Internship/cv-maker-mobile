import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/cv_template.dart';
import '../../../../core/widgets/app_sheet.dart';

Future<String?> showRenameCvDialog(BuildContext context, CvModel cv) async {
  final controller = TextEditingController(text: cv.title);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Đổi tên CV'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Tên hồ sơ mới',
          prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Lưu tên'),
        ),
      ],
    ),
  );
  final title = controller.text.trim();
  controller.dispose();
  if (confirmed != true || title.isEmpty || title == cv.title) return null;
  return title;
}

Future<bool> showDeleteCvConfirmation(BuildContext context, CvModel cv) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xoá CV?'),
          content: Text('Bạn có chắc muốn xoá hồ sơ “${cv.title}” không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Xoá'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> showPremiumTemplateInfo(
  BuildContext context,
  CvTemplate template, {
  VoidCallback? onViewProPlans,
}) {
  return showAppSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFEEF2FF),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.primarySlate,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              template.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${template.description}\nMẫu này dành cho tài khoản Pro.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onViewProPlans?.call();
                },
                child: const Text('Xem gói Pro'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Để sau'),
            ),
          ],
        ),
      ),
    ),
  );
}
