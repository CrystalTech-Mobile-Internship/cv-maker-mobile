import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/widgets/floating_launcher.dart';
import '../../../core/widgets/home_fallback_leading.dart';
import '../domain/job_application.dart';
import 'job_tracker_controller.dart';

/// Free tool: keep track of the jobs you saved, applied to and heard back
/// from. Everything stays on this device.
class JobTrackerScreen extends ConsumerStatefulWidget {
  const JobTrackerScreen({super.key});

  @override
  ConsumerState<JobTrackerScreen> createState() => _JobTrackerScreenState();
}

class _JobTrackerScreenState extends ConsumerState<JobTrackerScreen> {
  JobApplicationStatus? _filter;

  Future<void> _openEditor([JobApplication? item]) async {
    final result = await showModalBottomSheet<_EditResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _JobEditorSheet(item: item),
    );
    if (result == null || !mounted) return;
    final controller = ref.read(jobTrackerProvider.notifier);
    if (result.delete && item != null) {
      await controller.remove(item.id);
      return;
    }
    final draft = result.item!;
    if (item == null) {
      await controller.add(
        company: draft.company,
        role: draft.role,
        status: draft.status,
        appliedOn: draft.appliedOn,
        link: draft.link,
        note: draft.note,
      );
    } else {
      await controller.update(draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(jobTrackerProvider);
    final items = async.asData?.value ?? const <JobApplication>[];
    final visible = _filter == null
        ? items
        : items.where((e) => e.status == _filter).toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        leading: homeFallbackLeading(context),
        title: Text(tr('Theo dõi ứng tuyển', 'Job tracker')),
      ),
      floatingActionButton: items.isEmpty
          ? null
          : FloatingLauncher(
              key: const Key('job-tracker-add'),
              icon: const Icon(Icons.add_rounded),
              label: tr('Thêm việc', 'Add job'),
              showLabel: true,
              onPressed: _openEditor,
            ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(
            tr(
              'Không đọc được danh sách. Hãy mở lại trang.',
              'Could not load the list. Please reopen the page.',
            ),
          ),
        ),
        data: (_) => items.isEmpty
            ? _EmptyTracker(onAdd: _openEditor)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      _StatusFilter(
                        items: items,
                        selected: _filter,
                        onSelect: (status) => setState(() => _filter = status),
                      ),
                      const SizedBox(height: 14),
                      if (visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            tr(
                              'Chưa có việc nào ở mục này.',
                              'Nothing here yet.',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.mutedText),
                          ),
                        ),
                      for (final item in visible)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _JobCard(
                            item: item,
                            onTap: () => _openEditor(item),
                            onStatus: (status) => ref
                                .read(jobTrackerProvider.notifier)
                                .setStatus(item.id, status),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

Color _statusColor(JobApplicationStatus status) => switch (status) {
  JobApplicationStatus.saved => AppTheme.mutedText,
  JobApplicationStatus.applied => AppTheme.brandIndigo,
  JobApplicationStatus.interview => AppTheme.warningAmber,
  JobApplicationStatus.offer => AppTheme.successGreen,
  JobApplicationStatus.rejected => AppTheme.dangerRose,
};

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

class _EmptyTracker extends StatelessWidget {
  const _EmptyTracker({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.indigoSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.work_history_outlined,
                  size: 30,
                  color: AppTheme.brandIndigo,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr(
                  'Ghi lại các việc bạn ứng tuyển',
                  'Track the jobs you apply to',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  'Biết việc nào đã nộp, việc nào hẹn phỏng vấn. Miễn phí và chỉ lưu trên máy này.',
                  'See what you applied to and which interviews are coming. Free, and kept on this device.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.mutedText, height: 1.4),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('job-tracker-add-first'),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: Text(tr('Thêm việc đầu tiên', 'Add your first job')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<JobApplication> items;
  final JobApplicationStatus? selected;
  final ValueChanged<JobApplicationStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    int count(JobApplicationStatus s) =>
        items.where((e) => e.status == s).length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text('${tr('Tất cả', 'All')} ${items.length}'),
          selected: selected == null,
          onSelected: (_) => onSelect(null),
        ),
        for (final status in JobApplicationStatus.values)
          ChoiceChip(
            label: Text('${status.label} ${count(status)}'),
            selected: selected == status,
            onSelected: (_) => onSelect(selected == status ? null : status),
          ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.item,
    required this.onTap,
    required this.onStatus,
  });

  final JobApplication item;
  final VoidCallback onTap;
  final ValueChanged<JobApplicationStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.softBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        item.company,
                        if (item.appliedOn != null)
                          tr(
                            'Nộp ${_date(item.appliedOn!)}',
                            'Applied ${_date(item.appliedOn!)}',
                          ),
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.mutedText),
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<JobApplicationStatus>(
                tooltip: tr('Đổi trạng thái', 'Change status'),
                onSelected: onStatus,
                itemBuilder: (_) => [
                  for (final status in JobApplicationStatus.values)
                    PopupMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: _statusColor(status),
                          ),
                          const SizedBox(width: 10),
                          Text(status.label),
                        ],
                      ),
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.status.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(Icons.expand_more_rounded, size: 16, color: color),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditResult {
  const _EditResult.save(JobApplication this.item) : delete = false;
  const _EditResult.delete() : item = null, delete = true;

  final JobApplication? item;
  final bool delete;
}

class _JobEditorSheet extends StatefulWidget {
  const _JobEditorSheet({this.item});

  final JobApplication? item;

  @override
  State<_JobEditorSheet> createState() => _JobEditorSheetState();
}

class _JobEditorSheetState extends State<_JobEditorSheet> {
  late final _role = TextEditingController(text: widget.item?.role);
  late final _company = TextEditingController(text: widget.item?.company);
  late final _link = TextEditingController(text: widget.item?.link);
  late final _note = TextEditingController(text: widget.item?.note);
  late JobApplicationStatus _status =
      widget.item?.status ?? JobApplicationStatus.saved;
  late DateTime? _appliedOn = widget.item?.appliedOn;
  String? _error;

  @override
  void dispose() {
    _role.dispose();
    _company.dispose();
    _link.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _appliedOn?.toLocal() ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _appliedOn = picked.toUtc());
  }

  void _save() {
    if (_role.text.trim().isEmpty || _company.text.trim().isEmpty) {
      setState(
        () => _error = tr(
          'Hãy nhập vị trí và tên công ty.',
          'Enter the job title and company.',
        ),
      );
      return;
    }
    final base =
        widget.item ??
        JobApplication(
          id: '',
          company: '',
          role: '',
          status: _status,
          updatedAt: DateTime.now().toUtc(),
        );
    Navigator.pop(
      context,
      _EditResult.save(
        base.copyWith(
          role: _role.text.trim(),
          company: _company.text.trim(),
          link: _link.text.trim(),
          note: _note.text.trim(),
          status: _status,
          appliedOn: _appliedOn,
          clearAppliedOn: _appliedOn == null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? tr('Sửa việc', 'Edit job') : tr('Thêm việc', 'Add job'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('job-role'),
              controller: _role,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: tr('Vị trí', 'Job title')),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('job-company'),
              controller: _company,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: tr('Công ty', 'Company')),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<JobApplicationStatus>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: tr('Trạng thái', 'Status'),
              ),
              items: [
                for (final status in JobApplicationStatus.values)
                  DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: (value) => setState(() {
                _status = value ?? _status;
                if (_status != JobApplicationStatus.saved) {
                  _appliedOn ??= DateTime.now().toUtc();
                }
              }),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(
                _appliedOn == null
                    ? tr('Chọn ngày nộp', 'Pick the date applied')
                    : tr(
                        'Ngày nộp: ${_date(_appliedOn!)}',
                        'Applied on ${_date(_appliedOn!)}',
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _link,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: tr('Link tin tuyển dụng', 'Job posting link'),
                suffixIcon: _link.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: tr('Sao chép', 'Copy'),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () =>
                            Clipboard.setData(ClipboardData(text: _link.text)),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: tr('Ghi chú', 'Notes'),
                hintText: tr(
                  'Lịch phỏng vấn, người liên hệ, mức lương...',
                  'Interview time, contact person, salary...',
                ),
              ),
            ),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppTheme.dangerRose)),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (editing)
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, const _EditResult.delete()),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.dangerRose,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(tr('Xóa', 'Delete')),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('Hủy', 'Cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('job-save'),
                  onPressed: _save,
                  child: Text(tr('Lưu', 'Save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
