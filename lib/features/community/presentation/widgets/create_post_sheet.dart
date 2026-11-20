import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/community_models.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/i18n/app_language.dart';

/// Collects a validated [CommunityPostDraft]. Returns null when cancelled.
Future<CommunityPostDraft?> showCreatePostSheet(BuildContext context) {
  return showAppSheet<CommunityPostDraft>(
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
    CommunityPostKind.job => tr(
      'Mô tả vị trí, yêu cầu chính, hình thức làm việc, cách ứng tuyển...',
      'Describe the role, main requirements, work type, how to apply...',
    ),
    CommunityPostKind.cvReview => tr(
      'Bạn ứng tuyển vị trí nào? Muốn được góp ý phần nào của CV? '
          '(Không đăng số điện thoại, email, địa chỉ.)',
      'What role are you applying for? Which part of your CV needs feedback? (Do not post phone numbers, emails or addresses.)',
    ),
    CommunityPostKind.discussion => tr(
      'Chia sẻ kinh nghiệm phỏng vấn, học tập, câu hỏi nghề nghiệp...',
      'Share interview tips, learning, career questions...',
    ),
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
          title: Text(
            tr('Bài viết có thông tin liên hệ', 'Post has contact details'),
          ),
          content: Text(
            tr(
              'Nội dung có vẻ chứa email hoặc số điện thoại. Mọi thành viên đều '
                  'xem được bài viết. Bạn vẫn muốn đăng?',
              'The text seems to contain an email or phone number. Every member can see the post. Post anyway?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('Sửa lại', 'Edit')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('Vẫn đăng', 'Post anyway')),
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
            Text(
              tr('Đăng bài', 'Post'),
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
                labelText: isJob
                    ? tr('Vị trí tuyển dụng', 'Job title')
                    : tr('Tiêu đề', 'Title'),
              ),
            ),
            if (isJob) ...[
              TextField(
                key: const ValueKey('post-company'),
                controller: _company,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: tr('Công ty', 'Company'),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _location,
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: tr('Địa điểm', 'Location'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _salary,
                      maxLength: 60,
                      decoration: InputDecoration(
                        labelText: tr('Mức lương', 'Salary'),
                      ),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _url,
                maxLength: 500,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: tr(
                    'Link ứng tuyển (https://...)',
                    'Apply link (https://...)',
                  ),
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
                labelText: tr('Nội dung', 'Text'),
                hintText: _bodyHint,
                alignLabelWithHint: true,
              ),
            ),
            TextField(
              controller: _tags,
              decoration: InputDecoration(
                labelText: tr(
                  'Thẻ (tối đa 5, cách nhau bởi dấu phẩy)',
                  'Tags (up to 5, separated by commas)',
                ),
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
              child: Text(tr('Đăng bài', 'Post')),
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                'Bài bị báo cáo nhiều lần sẽ tự ẩn.',
                'Posts reported many times are hidden automatically.',
              ),
              style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
