import '../models/community_models.dart';

class CommunityFailure implements Exception {
  const CommunityFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'CommunityFailure: $message';
}

abstract interface class CommunityRepository {
  /// Newest first. [before] paginates by creation time.
  Future<List<CommunityPost>> fetchPosts({
    CommunityPostKind? kind,
    String search = '',
    DateTime? before,
    int limit = 20,
  });

  Future<CommunityPost> createPost(
    CommunityPostDraft draft, {
    required String authorName,
  });

  Future<void> deletePost(String postId);

  Future<List<CommunityComment>> fetchComments(String postId);

  Future<CommunityComment> addComment(
    String postId,
    String body, {
    required String authorName,
  });

  Future<void> deleteComment(String commentId);

  /// Returns the new liked state.
  Future<bool> setLiked(String postId, {required bool liked});

  Future<void> report(String postId, String reason);
}
