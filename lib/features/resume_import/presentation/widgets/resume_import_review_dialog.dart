import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_template.dart';
import '../../domain/models/resume_import_draft.dart';
import '../../domain/services/resume_language.dart';

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
  late String _language = detectResumeLanguage(
    [
      widget.draft.summary,
      widget.draft.targetRole,
      widget.draft.rawText,
    ].join('\n'),
  );

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
    final screen = MediaQuery.sizeOf(context);
    final wide = screen.width >= 900;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // Wider than the default dialog so both columns have room.
      constraints: BoxConstraints(maxWidth: wide ? 980 : 720),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: wide ? 980 : 720,
          maxHeight: screen.height * 0.9,
        ),
        child: Column(
          // Shrinks to the content; scrolls only when it is really long.
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: _profileColumn(wide: true)),
                          const SizedBox(width: 24),
                          Expanded(flex: 5, child: _contentColumn()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _profileColumn(wide: false),
                          const SizedBox(height: 4),
                          _contentColumn(),
                        ],
                      ),
              ),
            ),
            const Divider(height: 1),
            Container(
              alignment: Alignment.centerRight,
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

  /// Name, contact details and summary.
  Widget _profileColumn({required bool wide}) {
    final warnings = widget.draft.warnings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.softBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.draft.sourceName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              for (final warning in warnings)
                Text(
                  warning,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _field(_title, 'Tên hồ sơ', Icons.description_outlined),
        _field(_name, 'Họ và tên', Icons.person_outline_rounded),
        _field(_role, 'Vị trí ứng tuyển', Icons.work_outline_rounded),
        if (wide)
          Row(
            children: [
              Expanded(child: _field(_email, 'Email', Icons.email_outlined)),
              const SizedBox(width: 12),
              Expanded(
                child: _field(_phone, 'Số điện thoại', Icons.phone_outlined),
              ),
            ],
          )
        else ...[
          _field(_email, 'Email', Icons.email_outlined),
          _field(_phone, 'Số điện thoại', Icons.phone_outlined),
        ],
        _field(_address, 'Địa chỉ', Icons.location_on_outlined),
        TextField(
          controller: _summary,
          minLines: wide ? 5 : 4,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Tóm tắt',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.subject_rounded),
          ),
        ),
      ],
    );
  }

  /// Template, language and what else was found in the file.
  Widget _contentColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: _templateId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Mẫu CV',
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
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'vi', label: Text('Tiếng Việt')),
            ButtonSegment(value: 'en', label: Text('English')),
          ],
          selected: {_language},
          onSelectionChanged: (value) {
            setState(() => _language = value.first);
          },
        ),
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
        ],
        if (widget.draft.skills.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Kỹ năng tìm thấy (${widget.draft.skills.length})',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final skill in widget.draft.skills)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.softBorder),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primarySlate,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          'Các mục sẽ được đưa vào đúng phần để bạn chỉnh sửa tiếp.',
          style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
        ),
      ],
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
