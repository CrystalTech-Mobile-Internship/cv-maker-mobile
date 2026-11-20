import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_community_repository.dart';
import '../../domain/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';
import '../controllers/community_feed_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'community_post_card.dart';
import 'create_post_sheet.dart';
import '../../../../core/i18n/app_language.dart';

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

/// Handles report/delete from a post card. Returns true when the post was
/// deleted.
Future<bool> handleCommunityPostAction(
  BuildContext context,
  WidgetRef ref,
  CommunityPost post,
  CommunityPostAction action,
) async {
  final repository = ref.read(communityRepositoryProvider);
  try {
    if (action == CommunityPostAction.delete) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('Xóa bài viết?', 'Delete post?')),
          content: Text(
            tr(
              'Bài viết và bình luận sẽ bị xóa vĩnh viễn.',
              'The post and its comments will be deleted for good.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('Hủy', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('Xóa', 'Delete')),
            ),
          ],
        ),
      );
      if (confirm != true) return false;
      await repository.deletePost(post.id);
      ref.read(communityFeedControllerProvider.notifier).remove(post.id);
      if (context.mounted) {
        _toast(context, tr('Đã xóa bài viết.', 'Post deleted.'));
      }
      return true;
    }

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr('Báo cáo bài viết', 'Report post')),
        children: [
          for (final option in [
            tr('Spam hoặc quảng cáo', 'Spam or advertising'),
            tr('Tin tuyển dụng lừa đảo', 'Fake job posting'),
            tr('Nội dung xúc phạm', 'Offensive content'),
            tr('Lộ thông tin cá nhân', 'Personal information exposed'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option),
              child: Text(option),
            ),
        ],
      ),
    );
    if (reason == null) return false;
    await repository.report(post.id, reason);
    if (context.mounted) {
      _toast(
        context,
        tr(
          'Cảm ơn bạn đã báo cáo. Bài viết sẽ được xem xét.',
          'Thanks for reporting. We will review the post.',
        ),
      );
    }
  } on CommunityFailure catch (failure) {
    if (context.mounted) _toast(context, failure.message);
  }
  return false;
}

/// Opens the composer and publishes the post at the top of the feed.
Future<void> createCommunityPost(BuildContext context, WidgetRef ref) async {
  final draft = await showCreatePostSheet(context);
  if (draft == null || !context.mounted) return;
  final user = ref.read(currentAuthUserProvider);
  try {
    final post = await ref
        .read(communityRepositoryProvider)
        .createPost(draft, authorName: user?.displayName ?? '');
    ref.read(communityFeedControllerProvider.notifier).prepend(post);
    if (context.mounted) _toast(context, tr('Đã đăng bài.', 'Posted.'));
  } on CommunityFailure catch (failure) {
    if (context.mounted) _toast(context, failure.message);
  }
}
