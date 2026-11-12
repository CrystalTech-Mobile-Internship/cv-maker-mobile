import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_community_repository.dart';
import '../../domain/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';
import '../controllers/community_feed_controller.dart';
import '../widgets/community_actions.dart';
import '../widgets/community_post_card.dart';
import '../widgets/create_post_sheet.dart';

/// Community tab: discussions, shared jobs and CV review requests.
class CommunityView extends ConsumerStatefulWidget {
  const CommunityView({super.key});

  @override
  ConsumerState<CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends ConsumerState<CommunityView> {
  final _search = TextEditingController();
  Timer? _debounce;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _ensureLoaded() {
    if (_loadedOnce || ref.read(currentAuthUserProvider) == null) return;
    _loadedOnce = true;
    ref.read(communityFeedControllerProvider.notifier).refresh();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(communityFeedControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _createPost() async {
    final draft = await showCreatePostSheet(context);
    if (draft == null || !mounted) return;
    final user = ref.read(currentAuthUserProvider);
    try {
      final post = await ref
          .read(communityRepositoryProvider)
          .createPost(draft, authorName: user?.displayName ?? '');
      ref.read(communityFeedControllerProvider.notifier).prepend(post);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đăng bài.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on CommunityFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAuthUserProvider);
    if (user == null) return const _SignInPrompt();
    if (!_loadedOnce) {
      // Signed in after this tab was created: load once the frame is done.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureLoaded();
      });
    }

    final state = ref.watch(communityFeedControllerProvider);
    final controller = ref.read(communityFeedControllerProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Tìm bài viết, vị trí, công ty...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                key: const ValueKey('community-create-post'),
                onPressed: _createPost,
                child: const Text('Đăng bài'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _FilterChip(
                label: 'Tất cả',
                selected: state.kind == null,
                onSelected: () => controller.setKind(null),
              ),
              for (final kind in CommunityPostKind.values)
                _FilterChip(
                  label: kind.label,
                  selected: state.kind == kind,
                  onSelected: () => controller.setKind(kind),
                ),
            ],
          ),
        ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: AppTheme.dangerRose,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(state.errorMessage!)),
                TextButton(
                  onPressed: controller.refresh,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.extentAfter < 300) {
                  controller.loadMore();
                }
                return false;
              },
              child: state.isLoading && state.posts.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.posts.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            'Chưa có bài viết nào. Hãy là người đầu tiên chia sẻ!',
                            style: TextStyle(color: AppTheme.mutedText),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount:
                          state.posts.length + (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.posts.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final post = state.posts[index];
                        return CommunityPostCard(
                          post: post,
                          isMine: post.authorId == user.id,
                          onOpen: () =>
                              context.push('/community/post', extra: post),
                          onLike: () => controller.toggleLike(post),
                          onAction: (action) => handleCommunityPostAction(
                            context,
                            ref,
                            post,
                            action,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.indigoSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.forum_outlined,
                color: AppTheme.brandIndigo,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cộng đồng việc làm',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đăng nhập để xem việc làm được chia sẻ, thảo luận kinh nghiệm và nhờ góp ý CV.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.mutedText, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/login?redirect=%2Fhome'),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
