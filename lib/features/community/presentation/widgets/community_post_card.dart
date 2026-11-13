import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/community_models.dart';

String communityTimeAgo(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now().toUtc()).difference(time.toUtc());
  if (diff.inMinutes < 1) return 'vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  final local = time.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

enum CommunityPostAction { report, delete }

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.isMine,
    required this.onOpen,
    required this.onLike,
    required this.onAction,
    this.expanded = false,
  });

  final CommunityPost post;
  final bool isMine;
  final bool expanded;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final ValueChanged<CommunityPostAction> onAction;

  @override
  Widget build(BuildContext context) {
    final jobLine = [
      post.jobCompany,
      post.jobLocation,
      post.jobSalary,
    ].whereType<String>().join(' · ');

    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: expanded ? null : onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.softBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _KindLabel(kind: post.kind),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${post.authorName} · ${communityTimeAgo(post.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ),
                  PopupMenuButton<CommunityPostAction>(
                    tooltip: 'Tùy chọn',
                    icon: const Icon(
                      Icons.more_horiz,
                      size: 20,
                      color: AppTheme.mutedText,
                    ),
                    onSelected: onAction,
                    itemBuilder: (context) => [
                      if (isMine)
                        const PopupMenuItem(
                          value: CommunityPostAction.delete,
                          child: Text('Xóa bài viết'),
                        )
                      else
                        const PopupMenuItem(
                          value: CommunityPostAction.report,
                          child: Text('Báo cáo vi phạm'),
                        ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  post.title,
                  maxLines: expanded ? null : 2,
                  overflow: expanded ? null : TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              if (jobLine.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  jobLine,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brandIndigo,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: expanded
                    ? SelectableText(
                        post.body,
                        style: const TextStyle(fontSize: 14, height: 1.45),
                      )
                    : Text(
                        post.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: AppTheme.primarySlate,
                        ),
                      ),
              ),
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  post.tags.map((tag) => '#$tag').join('  '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  TextButton.icon(
                    key: ValueKey('like-${post.id}'),
                    onPressed: onLike,
                    style: TextButton.styleFrom(
                      foregroundColor: post.likedByMe
                          ? AppTheme.brandIndigo
                          : AppTheme.mutedText,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(
                      post.likedByMe
                          ? Icons.thumb_up_alt
                          : Icons.thumb_up_alt_outlined,
                      size: 18,
                    ),
                    label: Text('${post.likeCount}'),
                  ),
                  TextButton.icon(
                    onPressed: expanded ? null : onOpen,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.mutedText,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.mode_comment_outlined, size: 18),
                    label: Text('${post.commentCount}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindLabel extends StatelessWidget {
  const _KindLabel({required this.kind});

  final CommunityPostKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.indigoSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        kind.label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.brandIndigo,
        ),
      ),
    );
  }
}
