import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/community_models.dart';

/// Collects a validated [CommunityPostDraft]. Returns null when cancelled.
Future<CommunityPostDraft?> showCreatePostSheet(BuildContext context) {
  return showModalBottomSheet<CommunityPostDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _CreatePostSheet(),
  );
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  var _kind = CommunityPostKind.discussion;
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _tags = TextEditingController();
  final _company = TextEditingController();
  final _location = TextEditingController();
  final _salary = TextEditingController();
  final _url = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _title,
      _body,
      _tags,
      _company,
      _location,
      _salary,
      _url,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _bodyHint => switch (_kind) {
    CommunityPostKind.job =>
      'Mô tả vị trí, yêu cầu chính, hình thức làm việc, cách ứng tuyển...',
    CommunityPostKind.cvReview =>
      'Bạn ứng tuyển vị trí nào? Muốn được góp ý phần nào của CV? '
          '(Không đăng số điện thoại, email, địa chỉ.)',
    CommunityPostKind.discussion =>
      'Chia sẻ kinh nghiệm phỏng vấn, học tập, câu hỏi nghề nghiệp...',
  };

  Future<void> _submit() async {
    final draft = CommunityPostDraft(
      kind: _kind,
      title: _title.text,
      body: _body.text,
      tags: _tags.text
          .split(RegExp(r'[,#\s]+'))
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty && t.length <= 30)
          .toSet()
          .take(5)
          .toList(),
      jobCompany: _kind == CommunityPostKind.job ? _company.text : null,
      jobLocation: _kind == CommunityPostKind.job ? _location.text : null,
      jobSalary: _kind == CommunityPostKind.job ? _salary.text : null,
      jobUrl: _kind == CommunityPostKind.job ? _url.text : null,
    );
    final error = draft.validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (draft.containsContactDetails) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bài viết có thông tin liên hệ'),
          content: const Text(
            'Nội dung có vẻ chứa email hoặc số điện thoại. Mọi thành viên đều '
            'xem được bài viết. Bạn vẫn muốn đăng?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Sửa lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vẫn đăng'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    if (mounted) Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    final isJob = _kind == CommunityPostKind.job;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Đăng bài',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<CommunityPostKind>(
              segments: [
                for (final kind in CommunityPostKind.values)
                  ButtonSegment(value: kind, label: Text(kind.label)),
              ],
              selected: {_kind},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => _kind = value.first),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('post-title'),
              controller: _title,
              maxLength: 140,
              decoration: InputDecoration(
                labelText: isJob ? 'Vị trí tuyển dụng' : 'Tiêu đề',
              ),
            ),
            if (isJob) ...[
              TextField(
                key: const ValueKey('post-company'),
                controller: _company,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Công ty'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _location,
                      maxLength: 120,
                      decoration: const InputDecoration(labelText: 'Địa điểm'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _salary,
                      maxLength: 60,
                      decoration: const InputDecoration(labelText: 'Mức lương'),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _url,
                maxLength: 500,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link ứng tuyển (https://...)',
                ),
              ),
            ],
            TextField(
              key: const ValueKey('post-body'),
              controller: _body,
              minLines: 5,
              maxLines: 10,
              maxLength: 4000,
              decoration: InputDecoration(
                labelText: 'Nội dung',
                hintText: _bodyHint,
                alignLabelWithHint: true,
              ),
            ),
            TextField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: 'Thẻ (tối đa 5, cách nhau bởi dấu phẩy)',
                hintText: 'flutter, intern, hanoi',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppTheme.dangerRose)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('post-submit'),
              onPressed: _submit,
              child: const Text('Đăng bài'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bài bị báo cáo nhiều lần sẽ tự ẩn.',
              style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
