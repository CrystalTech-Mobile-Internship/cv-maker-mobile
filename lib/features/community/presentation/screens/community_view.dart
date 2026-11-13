import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/community_models.dart';
import '../../data/community_live_updates.dart';
import '../controllers/community_feed_controller.dart';
import '../widgets/community_actions.dart';
import '../widgets/community_post_card.dart';
import '../../../../core/widgets/app_sheet.dart';

/// Community tab: discussions, shared jobs and CV review requests.
class CommunityView extends ConsumerStatefulWidget {
  const CommunityView({super.key});

  @override
  ConsumerState<CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends ConsumerState<CommunityView> {
  final _search = TextEditingController();
  Timer? _debounce;
  StreamSubscription<CommunityPostChange>? _live;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _live?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _ensureLoaded() {
    if (_loadedOnce || ref.read(currentAuthUserProvider) == null) return;
    _loadedOnce = true;
    final controller = ref.read(communityFeedControllerProvider.notifier);
    controller.refresh();
    _live ??= ref
        .read(communityLiveUpdatesProvider)
        .postChanges()
        .listen(controller.applyLiveChange, onError: (_) {});
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(communityFeedControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _openFilters() async {
    final controller = ref.read(communityFeedControllerProvider.notifier);
    final current = ref.read(communityFeedControllerProvider).kind;
    final options = <(CommunityPostKind?, String)>[
      (null, 'Tất cả'),
      for (final kind in CommunityPostKind.values) (kind, kind.label),
    ];
    await showAppSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          key: const ValueKey('community-filter-sheet'),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loại bài viết',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in options)
                    ChoiceChip(
                      label: Text(option.$2),
                      selected: current == option.$1,
                      showCheckmark: false,
                      onSelected: (_) {
                        controller.setKind(option.$1);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: state.kind == null
                  ? 'Tìm bài viết, vị trí, công ty...'
                  : 'Tìm trong ${state.kind!.label}',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: IconButton(
                key: const ValueKey('community-filter-button'),
                tooltip: 'Lọc',
                onPressed: _openFilters,
                icon: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: state.kind == null
                      ? AppTheme.mutedText
                      : AppTheme.brandIndigo,
                ),
              ),
              isDense: true,
            ),
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
