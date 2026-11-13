import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/community_live_updates.dart';
import '../../data/repositories/supabase_community_repository.dart';
import '../../domain/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityFeedState {
  const CommunityFeedState({
    this.posts = const [],
    this.kind,
    this.search = '',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
  });

  final List<CommunityPost> posts;
  final CommunityPostKind? kind;
  final String search;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  CommunityFeedState copyWith({
    List<CommunityPost>? posts,
    CommunityPostKind? kind,
    bool clearKind = false,
    String? search,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommunityFeedState(
      posts: posts ?? this.posts,
      kind: clearKind ? null : kind ?? this.kind,
      search: search ?? this.search,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class CommunityFeedController extends StateNotifier<CommunityFeedState> {
  CommunityFeedController(this._repository) : super(const CommunityFeedState());

  final CommunityRepository _repository;
  static const pageSize = 20;
  int _requestId = 0;

  Future<void> refresh() async {
    final request = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final posts = await _repository.fetchPosts(
        kind: state.kind,
        search: state.search,
        limit: pageSize,
      );
      if (!mounted || request != _requestId) return;
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.length == pageSize,
      );
    } on CommunityFailure catch (failure) {
      if (!mounted || request != _requestId) return;
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.posts.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final more = await _repository.fetchPosts(
        kind: state.kind,
        search: state.search,
        before: state.posts.last.createdAt,
        limit: pageSize,
      );
      if (!mounted) return;
      state = state.copyWith(
        posts: [...state.posts, ...more],
        isLoadingMore: false,
        hasMore: more.length == pageSize,
      );
    } on CommunityFailure catch (failure) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      );
    }
  }

  Future<void> setKind(CommunityPostKind? kind) {
    state = kind == null
        ? state.copyWith(clearKind: true)
        : state.copyWith(kind: kind);
    return refresh();
  }

  Future<void> setSearch(String search) {
    state = state.copyWith(search: search.trim());
    return refresh();
  }

  /// Optimistic like toggle; reverts when the server rejects it.
  Future<void> toggleLike(CommunityPost post) async {
    final liked = !post.likedByMe;
    _replace(
      post.copyWith(
        likedByMe: liked,
        likeCount: (post.likeCount + (liked ? 1 : -1)).clamp(0, 1 << 30),
      ),
    );
    try {
      await _repository.setLiked(post.id, liked: liked);
    } on CommunityFailure catch (failure) {
      if (!mounted) return;
      _replace(post);
      state = state.copyWith(errorMessage: failure.message);
    }
  }

  void prepend(CommunityPost post) {
    state = state.copyWith(posts: [post, ...state.posts]);
  }

  void remove(String postId) {
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
    );
  }

  void updateCommentCount(String postId, int count) {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;
    _replace(state.posts[index].copyWith(commentCount: count));
  }

  void dismissError() => state = state.copyWith(clearError: true);

  /// Applies a change pushed by the server (another user posted, liked or
  /// commented) without reloading the feed.
  void applyLiveChange(CommunityPostChange change) {
    final index = state.posts.indexWhere((p) => p.id == change.postId);
    switch (change.type) {
      case CommunityChangeType.removed:
        if (index >= 0) remove(change.postId);
      case CommunityChangeType.added:
        final post = change.post;
        if (post == null || index >= 0 || state.search.isNotEmpty) return;
        if (state.kind != null && state.kind != post.kind) return;
        prepend(post);
      case CommunityChangeType.updated:
        final post = change.post;
        if (post == null || index < 0) return;
        _replace(post.copyWith(likedByMe: state.posts[index].likedByMe));
    }
  }

  void _replace(CommunityPost post) {
    state = state.copyWith(
      posts: [for (final p in state.posts) p.id == post.id ? post : p],
    );
  }
}

final communityFeedControllerProvider =
    StateNotifierProvider<CommunityFeedController, CommunityFeedState>(
      (ref) => CommunityFeedController(ref.watch(communityRepositoryProvider)),
    );
