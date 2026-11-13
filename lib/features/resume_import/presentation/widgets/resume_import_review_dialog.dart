import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_template.dart';
import '../../domain/models/resume_import_draft.dart';

final class ResumeImportReviewResult {
  const ResumeImportReviewResult({
    required this.title,
    required this.templateId,
    required this.language,
    required this.fullName,
    required this.targetRole,
    required this.email,
    required this.phone,
    required this.address,
    required this.summary,
  });

  final String title;
  final String templateId;
  final String language;
  final String fullName;
  final String targetRole;
  final String email;
  final String phone;
  final String address;
  final String summary;
}

Future<ResumeImportReviewResult?> showResumeImportReviewDialog(
  BuildContext context,
  ResumeImportDraft draft,
) {
  return showDialog<ResumeImportReviewResult>(
    context: context,
    builder: (_) => _ResumeImportReviewDialog(draft: draft),
  );
}

class _ResumeImportReviewDialog extends StatefulWidget {
  const _ResumeImportReviewDialog({required this.draft});

  final ResumeImportDraft draft;

  @override
  State<_ResumeImportReviewDialog> createState() =>
      _ResumeImportReviewDialogState();
}

class _ResumeImportReviewDialogState extends State<_ResumeImportReviewDialog> {
  late final _title = TextEditingController(
    text: widget.draft.targetRole.isEmpty
        ? 'CV nhập từ ${widget.draft.sourceName}'
        : 'CV ${widget.draft.targetRole}',
  );
  late final _name = TextEditingController(text: widget.draft.fullName);
  late final _role = TextEditingController(text: widget.draft.targetRole);
  late final _email = TextEditingController(text: widget.draft.email);
  late final _phone = TextEditingController(text: widget.draft.phone);
  late final _address = TextEditingController(text: widget.draft.address);
  late final _summary = TextEditingController(text: widget.draft.summary);
  String _templateId = CvTemplateCatalog.freeTemplates.first.id;
  String _language = 'vi';

  @override
  void dispose() {
    for (final controller in [
      _title,
      _name,
      _role,
      _email,
      _phone,
      _address,
      _summary,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    color: AppTheme.brandIndigo,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Kiểm tra thông tin đã đọc',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.amberSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.draft.sourceName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        for (final warning in widget.draft.warnings)
                          Text(
                            '• $warning',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _field(_title, 'Tên hồ sơ', Icons.description_outlined),
                  _field(_name, 'Họ và tên', Icons.person_outline_rounded),
                  _field(_role, 'Vị trí ứng tuyển', Icons.work_outline_rounded),
                  _field(_email, 'Email', Icons.email_outlined),
                  _field(_phone, 'Số điện thoại', Icons.phone_outlined),
                  _field(_address, 'Địa chỉ', Icons.location_on_outlined),
                  TextField(
                    controller: _summary,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Tóm tắt',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.subject_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _templateId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Template áp dụng',
                      prefixIcon: Icon(Icons.palette_outlined),
                    ),
                    items: [
                      for (final template in CvTemplateCatalog.freeTemplates)
                        DropdownMenuItem(
                          value: template.id,
                          child: Text(
                            template.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _templateId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'vi', label: Text('Tiếng Việt')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {_language},
                    onSelectionChanged: (value) {
                      setState(() => _language = value.first);
                    },
                  ),
                  if (widget.draft.skills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Kỹ năng tìm thấy (${widget.draft.skills.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final skill in widget.draft.skills)
                          Chip(label: Text(skill)),
                      ],
                    ),
                  ],
                  if (_structuredItemCount > 0) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Học vấn, kinh nghiệm, dự án ($_structuredItemCount)',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.draft.educations.isNotEmpty)
                          _countChip(
                            Icons.school_outlined,
                            'Học vấn',
                            widget.draft.educations.length,
                          ),
                        if (widget.draft.experiences.isNotEmpty)
                          _countChip(
                            Icons.work_outline_rounded,
                            'Kinh nghiệm',
                            widget.draft.experiences.length,
                          ),
                        if (widget.draft.projects.isNotEmpty)
                          _countChip(
                            Icons.account_tree_outlined,
                            'Dự án',
                            widget.draft.projects.length,
                          ),
                        if (widget.draft.certifications.isNotEmpty)
                          _countChip(
                            Icons.workspace_premium_outlined,
                            'Chứng chỉ',
                            widget.draft.certifications.length,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Các mục này sẽ được đưa vào đúng tab để bạn kiểm tra và chỉnh sửa tiếp.',
                      style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                alignment: WrapAlignment.end,
                runAlignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Huỷ'),
                  ),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Lưu và chỉnh sửa tiếp'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  int get _structuredItemCount =>
      widget.draft.educations.length +
      widget.draft.experiences.length +
      widget.draft.projects.length +
      widget.draft.certifications.length;

  Widget _countChip(IconData icon, String label, int count) {
    return Chip(
      avatar: Icon(icon, size: 17, color: AppTheme.brandIndigo),
      label: Text('$label: $count'),
    );
  }

  void _submit() {
    if (_title.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      ResumeImportReviewResult(
        title: _title.text.trim(),
        templateId: _templateId,
        language: _language,
        fullName: _name.text.trim(),
        targetRole: _role.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        summary: _summary.text.trim(),
      ),
    );
  }
}
