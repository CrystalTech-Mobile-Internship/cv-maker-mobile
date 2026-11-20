import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../resume_import/presentation/resume_draft_saver.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../controllers/ai_interview_controller.dart';
import '../widgets/ai_access_guard.dart';
import '../../../../core/widgets/home_fallback_leading.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/i18n/app_language.dart';

/// Conversational CV builder: the AI interviews the user, then turns the
/// conversation into a CV draft that goes through the normal review dialog.
class AiInterviewScreen extends ConsumerStatefulWidget {
  const AiInterviewScreen({super.key});

  @override
  ConsumerState<AiInterviewScreen> createState() => _AiInterviewScreenState();
}

class _AiInterviewScreenState extends ConsumerState<AiInterviewScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _accessChecked = false;

  static List<String> get _quickReplies => [
    tr('Mình là sinh viên năm cuối ngành CNTT', 'I am a final-year IT student'),
    tr(
      'Mình muốn ứng tuyển Flutter Developer',
      'I want to apply as a Flutter Developer',
    ),
    tr(
      'Mình chưa có kinh nghiệm đi làm, chỉ có dự án',
      'I have no work experience yet, only projects',
    ),
    tr('Hãy hỏi mình về kỹ năng', 'Ask me about my skills'),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<bool> _checkAccess() async {
    if (_accessChecked) return true;
    final ok = await ensureAiAccess(
      context,
      ref,
      redirectPath: '/ai-interview',
    );
    _accessChecked = ok;
    return ok;
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    if (!await _checkAccess()) return;
    _input.clear();
    await ref.read(aiInterviewControllerProvider.notifier).send(text);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _generate() async {
    if (!await _checkAccess()) return;
    final draft = await ref
        .read(aiInterviewControllerProvider.notifier)
        .generate();
    if (draft == null || !mounted) return;
    final cv = await reviewAndSaveResumeDraft(
      context,
      ref,
      draft,
      idPrefix: 'ai',
    );
    if (cv == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'Đã tạo CV từ cuộc trò chuyện và lưu trên thiết bị.',
            'Your CV was created from the chat and saved on this device.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pushReplacement('/editor', extra: cv);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiInterviewControllerProvider);
    final controller = ref.read(aiInterviewControllerProvider.notifier);
    ref.listen(
      aiInterviewControllerProvider.select((s) => s.messages.length),
      (_, _) => _scrollToEnd(),
    );

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        leading: homeFallbackLeading(context),
        title: Text(tr('Tạo CV', 'Create CV')),
        actions: [
          const AiQuotaChip(),
          PopupMenuButton<String>(
            tooltip: tr('Tùy chọn', 'Options'),
            onSelected: (value) {
              if (value == 'restart') controller.restart();
              if (value == 'generate') _generate();
              if (value == 'vi' || value == 'en') {
                controller.switchLanguage(value);
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'vi',
                checked: state.language == 'vi',
                child: Text(tr('CV tiếng Việt', 'Vietnamese CV')),
              ),
              CheckedPopupMenuItem(
                value: 'en',
                checked: state.language == 'en',
                child: Text(tr('CV tiếng Anh', 'English CV')),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'generate',
                enabled: state.canGenerate,
                child: Text(tr('Tạo CV ngay', 'Create CV now')),
              ),
              PopupMenuItem(
                value: 'restart',
                child: Text(tr('Bắt đầu lại', 'Start over')),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: state.isBusy ? null : state.progress / 100,
            minHeight: 4,
            backgroundColor: AppTheme.indigoSurface,
          ),
        ),
      ),
      body: WebConstrainedWidth(
        maxWidth: 820,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount:
                      state.messages.length +
                      (state.isSending || state.showCreateOffer ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.messages.length) {
                      if (state.isSending) return const _TypingBubble();
                      return _CreateCvOffer(
                        english: state.language == 'en',
                        isGenerating: state.isGenerating,
                        onYes: _generate,
                        onNo: controller.declineOffer,
                      );
                    }
                    return _MessageBubble(message: state.messages[index]);
                  },
                ),
              ),
              if (state.errorMessage != null)
                _ErrorBanner(
                  message: state.errorMessage!,
                  code: state.errorCode,
                  onDismiss: controller.dismissError,
                ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    ActionChip(
                      key: const ValueKey('ai-chat-ats'),
                      avatar: const Icon(Icons.analytics_outlined, size: 18),
                      label: Text(tr('Chấm điểm CV', 'Score my CV')),
                      onPressed: () => context.push('/ats-scorer'),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      key: const ValueKey('ai-chat-practice'),
                      avatar: const Icon(
                        Icons.record_voice_over_outlined,
                        size: 18,
                      ),
                      label: Text(tr('Luyện phỏng vấn', 'Interview practice')),
                      onPressed: () => context.push('/interview-practice'),
                    ),
                    if (state.userTurns == 0)
                      for (final reply in _quickReplies) ...[
                        const SizedBox(width: 8),
                        ActionChip(
                          label: Text(reply),
                          onPressed: state.isBusy ? null : () => _send(reply),
                        ),
                      ],
                  ],
                ),
              ),
              _Composer(
                controller: _input,
                enabled: !state.isBusy,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width * 0.82).clamp(0, 640),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? AppTheme.brandIndigo : AppTheme.surfaceCard,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: isUser ? null : Border.all(color: AppTheme.softBorder),
          ),
          child: SelectableText(
            message.content,
            style: TextStyle(
              color: isUser ? Colors.white : AppTheme.primaryNavy,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Create the CV now?" with yes / no answers, shown under the last reply
/// once the conversation has enough to work with.
class _CreateCvOffer extends StatelessWidget {
  const _CreateCvOffer({
    required this.english,
    required this.isGenerating,
    required this.onYes,
    required this.onNo,
  });

  final bool english;
  final bool isGenerating;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const ValueKey('ai-create-offer'),
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppTheme.softBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              english
                  ? 'I have enough to draft your CV. Create it now? '
                        '(${AiCreditCost.generateCv} uses)'
                  : tr(
                      'Mình đã có đủ thông tin. Bạn có muốn tạo CV ngay không? '
                          '(${AiCreditCost.generateCv} lượt)',
                      'I have enough information. Create your CV now? (${AiCreditCost.generateCv} uses)',
                    ),
              style: const TextStyle(color: AppTheme.primaryNavy, height: 1.4),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  key: const ValueKey('ai-generate-cv'),
                  onPressed: isGenerating ? null : onYes,
                  child: Text(
                    isGenerating
                        ? (english
                              ? 'Creating...'
                              : tr('Đang soạn CV...', 'Writing your CV...'))
                        : (english ? 'Yes' : tr('Có', 'Yes')),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  key: const ValueKey('ai-decline-cv'),
                  onPressed: isGenerating ? null : onNo,
                  child: Text(english ? 'No' : tr('Không', 'No')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              tr('Đang trả lời...', 'Replying...'),
              style: TextStyle(color: AppTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.code,
    required this.onDismiss,
  });

  final String message;
  final AiWritingFailureCode? code;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final quota = code == AiWritingFailureCode.quotaExceeded;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: quota
            ? AppTheme.amberSurface
            : AppTheme.dangerRose.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            quota ? Icons.hourglass_bottom_rounded : Icons.error_outline,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          if (quota)
            TextButton(
              onPressed: () => context.push('/upgrade-pro'),
              child: Text(tr('Nâng cấp', 'Upgrade')),
            ),
          IconButton(
            tooltip: tr('Đóng', 'Close'),
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('ai-chat-input'),
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              maxLength: 1500,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: tr(
                  'Nhập câu trả lời (${AiCreditCost.interview} lượt AI mỗi tin)',
                  'Type your answer (${AiCreditCost.interview} AI use per message)',
                ),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const ValueKey('ai-chat-send'),
            tooltip: tr('Gửi', 'Send'),
            onPressed: enabled ? onSend : null,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.brandIndigo,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.softBorder,
            ),
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
