import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_community_repository.dart';
import '../../domain/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';
import '../controllers/community_feed_controller.dart';
import 'community_post_card.dart';

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
          title: const Text('Xóa bài viết?'),
          content: const Text('Bài viết và bình luận sẽ bị xóa vĩnh viễn.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );
      if (confirm != true) return false;
      await repository.deletePost(post.id);
      ref.read(communityFeedControllerProvider.notifier).remove(post.id);
      if (context.mounted) _toast(context, 'Đã xóa bài viết.');
      return true;
    }

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Báo cáo bài viết'),
        children: [
          for (final option in const [
            'Spam hoặc quảng cáo',
            'Tin tuyển dụng lừa đảo',
            'Nội dung xúc phạm',
            'Lộ thông tin cá nhân',
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
      _toast(context, 'Cảm ơn bạn đã báo cáo. Bài viết sẽ được xem xét.');
    }
  } on CommunityFailure catch (failure) {
    if (context.mounted) _toast(context, failure.message);
  }
  return false;
}
