import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../resume_import/presentation/resume_draft_saver.dart';
import '../../domain/models/ai_assistant_models.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../controllers/ai_interview_controller.dart';
import '../widgets/ai_access_guard.dart';

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

  static const _quickReplies = [
    'Mình là sinh viên năm cuối ngành CNTT',
    'Mình muốn ứng tuyển Flutter Developer',
    'Mình chưa có kinh nghiệm đi làm, chỉ có dự án',
    'Hãy hỏi mình về kỹ năng',
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
      const SnackBar(
        content: Text('Đã tạo CV từ cuộc trò chuyện và lưu trên thiết bị.'),
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
        title: const Text('Tạo CV cùng AI'),
        actions: [
          const AiQuotaChip(),
          PopupMenuButton<String>(
            tooltip: 'Tùy chọn',
            onSelected: (value) {
              if (value == 'restart') controller.restart();
              if (value == 'vi' || value == 'en') {
                controller.switchLanguage(value);
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'vi',
                checked: state.language == 'vi',
                child: const Text('CV tiếng Việt'),
              ),
              CheckedPopupMenuItem(
                value: 'en',
                checked: state.language == 'en',
                child: const Text('CV tiếng Anh'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'restart', child: Text('Bắt đầu lại')),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: state.messages.length + (state.isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.messages.length) {
                    return const _TypingBubble();
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
            if (state.userTurns == 0)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _quickReplies.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ActionChip(
                    label: Text(_quickReplies[index]),
                    onPressed: state.isBusy
                        ? null
                        : () => _send(_quickReplies[index]),
                  ),
                ),
              ),
            _Composer(
              controller: _input,
              enabled: !state.isBusy,
              onSend: _send,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('ai-generate-cv'),
                  onPressed: state.canGenerate ? _generate : null,
                  icon: state.isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.description_outlined),
                  label: Text(
                    state.isGenerating
                        ? 'AI đang soạn CV...'
                        : state.canGenerate
                        ? 'Tạo CV từ cuộc trò chuyện (${AiCreditCost.generateCv} lượt)'
                        : 'Trả lời thêm vài câu để tạo CV',
                  ),
                ),
              ),
            ),
          ],
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
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
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

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
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
              'AI đang trả lời...',
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
              child: const Text('Nâng cấp'),
            ),
          IconButton(
            tooltip: 'Đóng',
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
              decoration: const InputDecoration(
                hintText: 'Nhập câu trả lời của bạn...',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const ValueKey('ai-chat-send'),
            tooltip: 'Gửi',
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
