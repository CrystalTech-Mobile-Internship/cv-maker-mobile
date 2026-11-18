import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../../domain/services/cv_section_edit_mapper.dart';
import '../controllers/cv_ai_edit_controller.dart';
import 'ai_access_guard.dart';

/// Side chat on the preview page: pick a section, say how to change it,
/// then apply or skip the rewritten text.
class CvAiEditPanel extends ConsumerStatefulWidget {
  const CvAiEditPanel({
    super.key,
    required this.cv,
    required this.section,
    required this.onSectionChanged,
    required this.onApply,
    this.onClose,
  });

  final CvModel cv;

  /// One of [CvEditableSection.all].
  final String section;
  final ValueChanged<String> onSectionChanged;
  final ValueChanged<CvModel> onApply;
  final VoidCallback? onClose;

  @override
  ConsumerState<CvAiEditPanel> createState() => _CvAiEditPanelState();
}

class _CvAiEditPanelState extends ConsumerState<CvAiEditPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  bool get _en => widget.cv.language == 'en';

  List<String> get _quickRequests => _en
      ? const [
          'Make it shorter',
          'Focus on results',
          'More professional',
          'Fix spelling',
        ]
      : const [
          'Viết ngắn gọn hơn',
          'Nhấn mạnh kết quả',
          'Chuyên nghiệp hơn',
          'Sửa lỗi chính tả',
        ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    final ok = await ensureAiAccess(context, ref, redirectPath: '/home');
    if (!ok || !mounted) return;
    _input.clear();
    final hasContent = await ref
        .read(cvAiEditControllerProvider.notifier)
        .request(cv: widget.cv, section: widget.section, instruction: text);
    if (!hasContent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _en
                ? 'This section is empty. Add content in the editor first.'
                : 'Mục này chưa có nội dung. Hãy nhập ở trang chỉnh sửa trước.',
          ),
        ),
      );
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _apply(int index, CvAiEditMessage message) {
    final proposal = message.proposal;
    final section = message.section;
    if (proposal == null || section == null) return;
    widget.onApply(CvSectionEditMapper.apply(widget.cv, section, proposal));
    ref
        .read(cvAiEditControllerProvider.notifier)
        .markProposal(index, CvAiProposalStatus.applied);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cvAiEditControllerProvider);
    final controller = ref.read(cvAiEditControllerProvider.notifier);
    ref.listen(
      cvAiEditControllerProvider.select((s) => s.messages.length),
      (_, _) => _scrollToEnd(),
    );

    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  size: 20,
                  color: AppTheme.brandIndigo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _en ? 'Ask to edit' : 'Nhờ sửa CV',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
                const AiQuotaChip(),
                if (widget.onClose != null)
                  IconButton(
                    tooltip: _en ? 'Close (Ctrl + K)' : 'Đóng (Ctrl + K)',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final section in CvEditableSection.all)
                  ChoiceChip(
                    key: ValueKey('ai-edit-section-$section'),
                    label: Text(CvEditableSection.label(section, english: _en)),
                    selected: widget.section == section,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => widget.onSectionChanged(section),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyHint(
                    english: _en,
                    section: widget.section,
                    requests: _quickRequests,
                    onRequest: state.isBusy ? null : _send,
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: state.messages.length + (state.isBusy ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.messages.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _en ? 'Rewriting...' : 'Đang sửa...',
                                style: const TextStyle(
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final message = state.messages[index];
                      if (message.fromUser) {
                        return _UserBubble(
                          text: message.text,
                          section: CvEditableSection.label(
                            message.section ?? '',
                            english: _en,
                          ),
                        );
                      }
                      return _ProposalCard(
                        message: message,
                        english: _en,
                        onApply: () => _apply(index, message),
                        onDismiss: () => controller.markProposal(
                          index,
                          CvAiProposalStatus.dismissed,
                        ),
                      );
                    },
                  ),
          ),
          if (state.errorMessage != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
              decoration: BoxDecoration(
                color: state.errorCode == AiWritingFailureCode.quotaExceeded
                    ? AppTheme.amberSurface
                    : AppTheme.dangerRose.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(state.errorMessage!)),
                  if (state.errorCode == AiWritingFailureCode.quotaExceeded)
                    TextButton(
                      onPressed: () => context.push('/upgrade-pro'),
                      child: Text(_en ? 'Upgrade' : 'Nâng cấp'),
                    ),
                  IconButton(
                    tooltip: _en ? 'Close' : 'Đóng',
                    onPressed: controller.dismissError,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('ai-edit-input'),
                    controller: _input,
                    enabled: !state.isBusy,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 500,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: _en
                          ? 'How should it change?'
                          : 'Bạn muốn sửa thế nào?',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const ValueKey('ai-edit-send'),
                  tooltip: _en ? 'Send' : 'Gửi',
                  onPressed: state.isBusy ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.english,
    required this.section,
    required this.requests,
    required this.onRequest,
  });

  final bool english;
  final String section;
  final List<String> requests;
  final ValueChanged<String>? onRequest;

  @override
  Widget build(BuildContext context) {
    final label = CvEditableSection.label(section, english: english);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          english
              ? 'Pick a section, then say how to change it. You choose whether to apply the result. Each request uses ${AiCreditCost.editSection} credit.'
              : 'Chọn một mục rồi nói bạn muốn sửa thế nào. Bạn xem trước rồi mới áp dụng. Mỗi lần dùng ${AiCreditCost.editSection} lượt.',
          style: const TextStyle(color: AppTheme.mutedText, height: 1.4),
        ),
        const SizedBox(height: 12),
        Text(
          english ? 'Quick requests for $label' : 'Gợi ý cho mục $label',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final request in requests)
              ActionChip(
                label: Text(request),
                onPressed: onRequest == null ? null : () => onRequest!(request),
              ),
          ],
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text, required this.section});

  final String text;
  final String section;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: AppTheme.brandIndigo,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              section,
              style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 11),
            ),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.message,
    required this.english,
    required this.onApply,
    required this.onDismiss,
  });

  final CvAiEditMessage message;
  final bool english;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final lines = [
      for (final block in message.proposal?.blocks.values ?? <List<String>>[])
        ...block,
    ];
    final isSkills = message.section == CvEditableSection.skills;
    return Container(
      key: const ValueKey('ai-edit-proposal'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.text.isNotEmpty) ...[
            Text(
              message.text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
          ],
          if (isSkills)
            Text(lines.join(', '), style: const TextStyle(height: 1.4))
          else
            for (final line in lines.take(12))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.section == CvEditableSection.summary
                      ? line
                      : '• $line',
                  style: const TextStyle(height: 1.4),
                ),
              ),
          const SizedBox(height: 8),
          switch (message.status) {
            CvAiProposalStatus.applied => Text(
              english ? 'Applied to the CV.' : 'Đã áp dụng vào CV.',
              style: const TextStyle(
                color: AppTheme.successGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            CvAiProposalStatus.dismissed => Text(
              english ? 'Skipped.' : 'Đã bỏ qua.',
              style: const TextStyle(color: AppTheme.mutedText),
            ),
            _ => Row(
              children: [
                FilledButton(
                  key: const ValueKey('ai-edit-apply'),
                  onPressed: onApply,
                  child: Text(english ? 'Apply' : 'Áp dụng'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDismiss,
                  child: Text(english ? 'Skip' : 'Bỏ qua'),
                ),
              ],
            ),
          },
        ],
      ),
    );
  }
}
