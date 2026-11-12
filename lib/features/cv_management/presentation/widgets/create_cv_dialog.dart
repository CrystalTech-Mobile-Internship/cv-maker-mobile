import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import 'cv_template_picker.dart';

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
      title: const Row(
        children: [
          Icon(Icons.post_add_rounded, color: AppTheme.primarySlate),
          SizedBox(width: 8),
          Text('Tạo hồ sơ CV mới'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tên hồ sơ',
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
            const Text(
              'Dữ liệu ban đầu',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _sourceCvId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.content_copy_outlined),
                helperText: 'Dùng lại thông tin nhưng tạo một CV độc lập.',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Bắt đầu với hồ sơ trống'),
                ),
                for (final cv in widget.existingCvs)
                  DropdownMenuItem<String?>(
                    value: cv.id,
                    child: Text(
                      'Dùng dữ liệu: ${cv.title}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _sourceCvId = value),
            ),
            const SizedBox(height: 16),
            const Text('Mẫu CV', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            CvTemplatePicker(
              isPro: widget.isPro,
              selectedId: _selectedTemplate,
              onChanged: (value) => setState(() => _selectedTemplate = value),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ngôn ngữ mặc định',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'vi',
                  icon: Icon(Icons.translate_rounded, size: 17),
                  label: Text('Tiếng Việt'),
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
          child: const Text('Huỷ'),
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
          label: const Text('Tạo ngay'),
        ),
      ],
    );
  }
}
