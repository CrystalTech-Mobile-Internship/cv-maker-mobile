import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import 'cv_template_picker.dart';
import '../../../../core/i18n/app_language.dart';

final class CreateCvRequest {
  const CreateCvRequest({
    required this.title,
    required this.templateId,
    required this.language,
    this.sourceCv,
  });

  final String title;
  final String templateId;
  final String language;
  final CvModel? sourceCv;
}

Future<CreateCvRequest?> showCreateCvDialog(
  BuildContext context, {
  String initialTemplate = 'harvard_ats',
  List<CvModel> existingCvs = const [],
  bool isPro = false,
}) {
  return showDialog<CreateCvRequest>(
    context: context,
    builder: (_) => _CreateCvDialog(
      initialTemplate: initialTemplate,
      existingCvs: existingCvs,
      isPro: isPro,
    ),
  );
}

class _CreateCvDialog extends StatefulWidget {
  const _CreateCvDialog({
    required this.initialTemplate,
    required this.existingCvs,
    this.isPro = false,
  });

  final bool isPro;

  final String initialTemplate;
  final List<CvModel> existingCvs;

  @override
  State<_CreateCvDialog> createState() => _CreateCvDialogState();
}

class _CreateCvDialogState extends State<_CreateCvDialog> {
  final _titleController = TextEditingController();
  late String _selectedTemplate = widget.initialTemplate;
  String _language = 'vi';
  String? _sourceCvId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.post_add_rounded, color: AppTheme.primarySlate),
          SizedBox(width: 8),
          Text(tr('Tạo hồ sơ CV mới', 'New CV')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Tên hồ sơ', 'CV name'),
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'VD: CV Flutter Software Engineer',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('Dữ liệu ban đầu', 'Start from'),
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _sourceCvId,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.content_copy_outlined),
                helperText: tr(
                  'Có thể chép từ CV đã có.',
                  'You can copy from an existing CV.',
                ),
                helperMaxLines: 2,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(tr('Bắt đầu với hồ sơ trống', 'Start blank')),
                ),
                for (final cv in widget.existingCvs)
                  DropdownMenuItem<String?>(
                    value: cv.id,
                    child: Text(
                      tr('Dùng dữ liệu: ${cv.title}', 'Copy from: ${cv.title}'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _sourceCvId = value),
            ),
            const SizedBox(height: 16),
            Text(
              tr('Mẫu CV', 'Templates'),
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            CvTemplatePicker(
              isPro: widget.isPro,
              selectedId: _selectedTemplate,
              onChanged: (value) => setState(() => _selectedTemplate = value),
            ),
            const SizedBox(height: 16),
            Text(
              tr('Ngôn ngữ mặc định', 'CV language'),
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'vi',
                  icon: Icon(Icons.translate_rounded, size: 17),
                  label: Text(tr('Tiếng Việt', 'Vietnamese')),
                ),
                ButtonSegment(
                  value: 'en',
                  icon: Icon(Icons.language_rounded, size: 17),
                  label: Text('English'),
                ),
              ],
              selected: {_language},
              onSelectionChanged: (value) {
                setState(() => _language = value.first);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Huỷ', 'Cancel')),
        ),
        FilledButton.icon(
          onPressed: _titleController.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  CreateCvRequest(
                    title: _titleController.text.trim(),
                    templateId: _selectedTemplate,
                    language: _language,
                    sourceCv: widget.existingCvs
                        .where((cv) => cv.id == _sourceCvId)
                        .firstOrNull,
                  ),
                ),
          icon: const Icon(Icons.check_rounded),
          label: Text(tr('Tạo ngay', 'Create')),
        ),
      ],
    );
  }
}
