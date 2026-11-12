import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_community_repository.dart';
import '../../domain/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';
import '../controllers/community_feed_controller.dart';
import '../widgets/community_actions.dart';
import '../widgets/community_post_card.dart';
import '../../../../core/widgets/home_fallback_leading.dart';

/// Post detail with comments.
class CommunityPostScreen extends ConsumerStatefulWidget {
  const CommunityPostScreen({super.key, required this.post});

  final CommunityPost post;

  @override
  ConsumerState<CommunityPostScreen> createState() =>
      _CommunityPostScreenState();
}

class _CommunityPostScreenState extends ConsumerState<CommunityPostScreen> {
  final _input = TextEditingController();
  List<CommunityComment>? _comments;
  String? _error;
  bool _sending = false;

  CommunityPost get _post {
    final feed = ref.watch(communityFeedControllerProvider).posts;
    return feed.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => widget.post,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final comments = await ref
          .read(communityRepositoryProvider)
          .fetchComments(widget.post.id);
      if (mounted) setState(() => _comments = comments);
    } on CommunityFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final comment = await ref
          .read(communityRepositoryProvider)
          .addComment(
            widget.post.id,
            text,
            authorName: ref.read(currentAuthUserProvider)?.displayName ?? '',
          );
      if (!mounted) return;
      _input.clear();
      final comments = [...?_comments, comment];
      setState(() => _comments = comments);
      ref
          .read(communityFeedControllerProvider.notifier)
          .updateCommentCount(widget.post.id, comments.length);
    } on CommunityFailure catch (failure) {
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

  Future<void> _deleteComment(CommunityComment comment) async {
    try {
      await ref.read(communityRepositoryProvider).deleteComment(comment.id);
      if (!mounted) return;
      final comments = [...?_comments]..removeWhere((c) => c.id == comment.id);
      setState(() => _comments = comments);
      ref
          .read(communityFeedControllerProvider.notifier)
          .updateCommentCount(widget.post.id, comments.length);
    } on CommunityFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final userId = ref.watch(currentAuthUserProvider)?.id;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        leading: homeFallbackLeading(context),
        title: Text(post.kind.label),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CommunityPostCard(
                    post: post,
                    isMine: post.authorId == userId,
                    expanded: true,
                    onOpen: () {},
                    onLike: () => ref
                        .read(communityFeedControllerProvider.notifier)
                        .toggleLike(post),
                    onAction: (action) async {
                      final deleted = await handleCommunityPostAction(
                        context,
                        ref,
                        post,
                        action,
                      );
                      if (deleted && context.mounted) Navigator.pop(context);
                    },
                  ),
                  if (post.jobUrl != null) ...[
                    const SizedBox(height: 12),
                    _ApplyLink(url: post.jobUrl!),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Bình luận (${_comments?.length ?? post.commentCount})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.dangerRose),
                    )
                  else if (_comments == null)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_comments!.isEmpty)
                    const Text(
                      'Chưa có bình luận nào.',
                      style: TextStyle(color: AppTheme.mutedText),
                    )
                  else
                    for (final comment in _comments!)
                      _CommentTile(
                        comment: comment,
                        canDelete: comment.authorId == userId,
                        onDelete: () => _deleteComment(comment),
                      ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceCard,
                border: Border(top: BorderSide(color: AppTheme.softBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('comment-input'),
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1500,
                      decoration: const InputDecoration(
                        hintText: 'Viết bình luận...',
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const ValueKey('comment-send'),
                    tooltip: 'Gửi',
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyLink extends StatelessWidget {
  const _ApplyLink({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final host = Uri.tryParse(url)?.host ?? url;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: AppTheme.mutedText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Link ứng tuyển',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  host,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đã sao chép link. Hãy kiểm tra kỹ tên miền trước khi mở.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Sao chép'),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  final CommunityComment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${comment.authorName} · ${communityTimeAgo(comment.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(comment.body),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: 'Xóa bình luận',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppTheme.mutedText,
              ),
            ),
        ],
      ),
    );
  }
}
