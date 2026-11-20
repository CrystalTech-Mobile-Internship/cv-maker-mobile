import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/app_language.dart';
import '../../../support/domain/support_models.dart';
import '../../data/supabase_admin_repository.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';
import 'admin_format.dart';

/// Inbox of every account that wrote to support. Wide screens show the list
/// and the open conversation side by side.
class AdminSupportTab extends ConsumerStatefulWidget {
  const AdminSupportTab({super.key});

  @override
  ConsumerState<AdminSupportTab> createState() => _AdminSupportTabState();
}

class _AdminSupportTabState extends ConsumerState<AdminSupportTab> {
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    final threads = ref.watch(adminThreadsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        final list = threads.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Message(
            error is AdminFailure
                ? error.message
                : tr('Chưa tải được tin nhắn.', 'Could not load messages.'),
          ),
          data: (items) => items.isEmpty
              ? _Message(
                  tr('Chưa có ai nhắn hỗ trợ.', 'No support messages yet.'),
                )
              : ListView.separated(
                  key: const Key('admin-threads'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 68),
                  itemBuilder: (context, index) {
                    final thread = items[index];
                    return _ThreadTile(
                      thread: thread,
                      selected: wide && thread.userId == _selectedUserId,
                      onTap: () {
                        if (wide) {
                          setState(() => _selectedUserId = thread.userId);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _ConversationPage(thread),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        );
        if (!wide) return list;

        SupportThread? selected;
        for (final thread in threads.valueOrNull ?? const <SupportThread>[]) {
          if (thread.userId == _selectedUserId) selected = thread;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 340,
              child: ColoredBox(color: AppTheme.surfaceCard, child: list),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: selected == null
                  ? _Message(
                      tr(
                        'Chọn một cuộc trò chuyện để xem và trả lời.',
                        'Pick a conversation to read and reply.',
                      ),
                    )
                  : AdminConversation(
                      key: ValueKey(selected.userId),
                      thread: selected,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.mutedText),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.thread,
    required this.selected,
    required this.onTap,
  });

  final SupportThread thread;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = thread.displayName.isEmpty ? thread.email : thread.displayName;
    final preview = thread.lastFromSupport
        ? tr('Bạn: ${thread.lastBody}', 'You: ${thread.lastBody}')
        : thread.lastBody;
    return Material(
      color: selected ? AppTheme.indigoSurface : Colors.transparent,
      child: InkWell(
        key: Key('admin-thread-${thread.userId}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.indigoSurface,
                foregroundColor: AppTheme.brandIndigo,
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: thread.hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          adminStamp(thread.lastAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: thread.hasUnread
                                  ? AppTheme.primaryNavy
                                  : AppTheme.mutedText,
                            ),
                          ),
                        ),
                        if (thread.hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.brandIndigo,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${thread.unread}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (thread.needsReply && !thread.hasUnread) ...[
                      const SizedBox(height: 4),
                      Text(
                        tr('Đã xem · chưa trả lời', 'Seen · not answered'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningAmber,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationPage extends StatelessWidget {
  const _ConversationPage(this.thread);

  final SupportThread thread;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(
          thread.displayName.isEmpty ? thread.email : thread.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(child: AdminConversation(thread: thread)),
    );
  }
}

/// One account's conversation with a reply box.
class AdminConversation extends ConsumerStatefulWidget {
  const AdminConversation({super.key, required this.thread});

  final SupportThread thread;

  @override
  ConsumerState<AdminConversation> createState() => _AdminConversationState();
}

class _AdminConversationState extends ConsumerState<AdminConversation> {
  final _input = TextEditingController();
  bool _sending = false;

  /// Last user message already marked as read, so each one is sent once.
  String? _markedId;

  Future<void> _markRead(List<SupportMessage> items) async {
    SupportMessage? lastFromUser;
    for (final message in items) {
      if (!message.fromSupport) lastFromUser = message;
    }
    final id = lastFromUser?.id ?? '';
    if (id == _markedId) return;
    _markedId = id;
    if (lastFromUser == null) return;
    try {
      await ref.read(adminRepositoryProvider).markRead(widget.thread.userId);
      ref.invalidate(adminThreadsProvider);
    } on AdminFailure {
      _markedId = null;
    }
  }

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
      await ref.read(adminRepositoryProvider).reply(widget.thread.userId, text);
      _input.clear();
      ref.invalidate(adminStatsProvider);
    } on AdminFailure catch (failure) {
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
    final thread = widget.thread;
    final messages = ref.watch(adminConversationProvider(thread.userId));
    ref.listen(adminConversationProvider(thread.userId), (_, next) {
      final items = next.valueOrNull;
      if (items != null) _markRead(items);
    });
    final loaded = messages.valueOrNull;
    if (loaded != null && _markedId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _markRead(loaded);
      });
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          color: AppTheme.surfaceCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                thread.displayName.isEmpty ? thread.email : thread.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNavy,
                ),
              ),
              if (thread.email.isNotEmpty)
                SelectableText(
                  thread.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: messages.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _Message(
              tr('Chưa tải được tin nhắn.', 'Could not load messages.'),
            ),
            data: (items) => ListView(
              key: const Key('admin-conversation'),
              reverse: true,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                for (final message in items.reversed) _Bubble(message),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCard,
            border: Border(top: BorderSide(color: AppTheme.softBorder)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('admin-reply-input'),
                  controller: _input,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: tr('Nhập câu trả lời...', 'Write a reply...'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('admin-reply-send'),
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

/// Replies sit on the right, the user's messages on the left.
class _Bubble extends StatelessWidget {
  const _Bubble(this.message);

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromSupport;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? AppTheme.brandIndigo : AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: mine ? null : Border.all(color: AppTheme.softBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  message.body,
                  style: TextStyle(
                    height: 1.4,
                    color: mine ? Colors.white : AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  adminStamp(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: mine
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.mutedText,
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
