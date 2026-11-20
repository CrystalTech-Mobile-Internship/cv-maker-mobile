import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/widgets/home_fallback_leading.dart';
import '../../../core/widgets/responsive_layout_builder.dart';
import '../../auth/presentation/auth_redirect.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../data/supabase_support_repository.dart';
import '../domain/support_models.dart';

/// Conversation with the support team, saved to the account so it is the
/// same on the web and in the app.
class SupportChatScreen extends ConsumerWidget {
  const SupportChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAuthUserProvider);
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        leading: homeFallbackLeading(context),
        title: Text(tr('Hỗ trợ', 'Support')),
      ),
      body: WebConstrainedWidth(
        maxWidth: 720,
        child: SafeArea(
          child: user == null ? const _SignInFirst() : const _Conversation(),
        ),
      ),
    );
  }
}

class _SignInFirst extends StatelessWidget {
  const _SignInFirst();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.support_agent_rounded,
              size: 40,
              color: AppTheme.brandIndigo,
            ),
            const SizedBox(height: 12),
            Text(
              tr('Đăng nhập để nhắn hỗ trợ', 'Sign in to message support'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                'Tin nhắn được lưu theo tài khoản để bạn xem lại trên web và điện thoại.',
                'Messages are saved to your account so you can see them on web and phone.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.mutedText, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  context.push(authEntryLocation('/login', '/support')),
              child: Text(tr('Đăng nhập', 'Sign in')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Conversation extends ConsumerStatefulWidget {
  const _Conversation();

  @override
  ConsumerState<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends ConsumerState<_Conversation> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(supportRepositoryProvider).send(text);
      _input.clear();
    } on SupportFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(supportMessagesProvider);
    final seenAt = ref.watch(supportSeenAtProvider).valueOrNull;
    return Column(
      children: [
        Expanded(
          child: messages.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Text(
                tr('Chưa tải được tin nhắn.', 'Could not load your messages.'),
                style: const TextStyle(color: AppTheme.mutedText),
              ),
            ),
            data: (items) => ListView(
              key: const Key('support-messages'),
              reverse: true,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                if (_isSeen(items, seenAt)) const _SeenLabel(),
                for (final message in items.reversed) _Bubble(message),
                const _Welcome(),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.softBorder)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('support-input'),
                  controller: _input,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: tr(
                      'Mô tả vấn đề bạn gặp...',
                      'Describe what you need help with...',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('support-send'),
                tooltip: tr('Gửi', 'Send'),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.brandIndigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// True when the last message is the user's and support has opened the
/// conversation since it was sent.
bool _isSeen(List<SupportMessage> items, DateTime? seenAt) {
  if (items.isEmpty || seenAt == null) return false;
  final last = items.last;
  return !last.fromSupport && !seenAt.isBefore(last.createdAt);
}

class _SeenLabel extends StatelessWidget {
  const _SeenLabel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          tr('Đã xem', 'Seen'),
          key: const Key('support-seen'),
          style: const TextStyle(fontSize: 11, color: AppTheme.mutedText),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _BubbleBox(
        fromSupport: true,
        child: Text(
          tr(
            'Chào bạn! Hãy nhắn vấn đề bạn gặp, chúng tôi sẽ trả lời sớm nhất có thể.',
            'Hi! Tell us what you need and we will reply as soon as we can.',
          ),
          style: const TextStyle(height: 1.4),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.message);

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final time = message.createdAt.toLocal();
    final stamp =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.day}/${time.month}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _BubbleBox(
        fromSupport: message.fromSupport,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.body,
              style: TextStyle(
                height: 1.4,
                color: message.fromSupport
                    ? AppTheme.primaryNavy
                    : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stamp,
              style: TextStyle(
                fontSize: 11,
                color: message.fromSupport
                    ? AppTheme.mutedText
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleBox extends StatelessWidget {
  const _BubbleBox({required this.fromSupport, required this.child});

  final bool fromSupport;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromSupport ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: fromSupport ? Colors.white : AppTheme.brandIndigo,
            borderRadius: BorderRadius.circular(14),
            border: fromSupport ? Border.all(color: AppTheme.softBorder) : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
