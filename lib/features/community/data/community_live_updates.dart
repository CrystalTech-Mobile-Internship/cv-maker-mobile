import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/models/community_models.dart';
import 'repositories/supabase_community_repository.dart';

enum CommunityChangeType { added, updated, removed }

class CommunityPostChange {
  const CommunityPostChange(this.type, {this.post, required this.postId});

  final CommunityChangeType type;
  final CommunityPost? post;
  final String postId;
}

class CommunityCommentChange {
  const CommunityCommentChange(
    this.type, {
    this.comment,
    required this.commentId,
  });

  final CommunityChangeType type;
  final CommunityComment? comment;
  final String commentId;
}

/// Pushes community changes from the server as they happen.
///
/// Rows are still filtered by row level security, so users only receive
/// posts and comments they are allowed to read.
class CommunityLiveUpdates {
  CommunityLiveUpdates({SupabaseClient? client}) : _provided = client;

  final SupabaseClient? _provided;

  SupabaseClient? get _client {
    final client = _provided ?? SupabaseService.client;
    if (client == null || client.auth.currentUser == null) return null;
    return client;
  }

  Stream<CommunityPostChange> postChanges() {
    return _listen<CommunityPostChange>(
      channelName: 'community-posts',
      table: 'community_posts',
      map: (type, row, oldRow) {
        final id = '${row['id'] ?? oldRow['id'] ?? ''}';
        if (id.isEmpty) return null;
        if (type == CommunityChangeType.removed) {
          return CommunityPostChange(type, postId: id);
        }
        if (row['is_hidden'] == true) {
          return CommunityPostChange(CommunityChangeType.removed, postId: id);
        }
        return CommunityPostChange(
          type,
          postId: id,
          post: SupabaseCommunityRepository.mapPost(row),
        );
      },
    );
  }

  Stream<CommunityCommentChange> commentChanges(String postId) {
    return _listen<CommunityCommentChange>(
      channelName: 'community-comments-$postId',
      table: 'community_comments',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'post_id',
        value: postId,
      ),
      map: (type, row, oldRow) {
        final id = '${row['id'] ?? oldRow['id'] ?? ''}';
        if (id.isEmpty) return null;
        if (type == CommunityChangeType.removed) {
          return CommunityCommentChange(type, commentId: id);
        }
        return CommunityCommentChange(
          type,
          commentId: id,
          comment: SupabaseCommunityRepository.mapComment(row),
        );
      },
    );
  }

  Stream<T> _listen<T>({
    required String channelName,
    required String table,
    PostgresChangeFilter? filter,
    required T? Function(
      CommunityChangeType type,
      Map<String, dynamic> row,
      Map<String, dynamic> oldRow,
    )
    map,
  }) {
    final client = _client;
    if (client == null) return const Stream.empty();

    late final StreamController<T> controller;
    RealtimeChannel? channel;
    controller = StreamController<T>(
      onListen: () {
        channel = client
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              filter: filter,
              callback: (payload) {
                final type = switch (payload.eventType) {
                  PostgresChangeEvent.insert => CommunityChangeType.added,
                  PostgresChangeEvent.delete => CommunityChangeType.removed,
                  _ => CommunityChangeType.updated,
                };
                try {
                  final change = map(
                    type,
                    Map<String, dynamic>.from(payload.newRecord),
                    Map<String, dynamic>.from(payload.oldRecord),
                  );
                  if (change != null && !controller.isClosed) {
                    controller.add(change);
                  }
                } catch (_) {
                  // A malformed row must not break the live feed.
                }
              },
            )
            .subscribe();
      },
      onCancel: () async {
        final active = channel;
        channel = null;
        if (active != null) await client.removeChannel(active);
      },
    );
    return controller.stream;
  }
}

final communityLiveUpdatesProvider = Provider<CommunityLiveUpdates>(
  (ref) => CommunityLiveUpdates(),
);
