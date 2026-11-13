import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';

class SupabaseCommunityRepository implements CommunityRepository {
  SupabaseCommunityRepository({SupabaseClient? client}) : _provided = client;

  final SupabaseClient? _provided;

  static const _postColumns =
      'id, author_id, author_name, kind, title, body, tags, job_company, '
      'job_location, job_url, job_salary, like_count, comment_count, created_at';

  SupabaseClient get _client {
    final client = _provided ?? SupabaseService.client;
    if (client == null) {
      throw const CommunityFailure(
        'Cộng đồng cần kết nối máy chủ. Hãy kiểm tra cấu hình và mạng.',
      );
    }
    if (client.auth.currentUser == null) {
      throw const CommunityFailure('Hãy đăng nhập để tham gia cộng đồng.');
    }
    return client;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on CommunityFailure {
      rethrow;
    } on PostgrestException catch (error) {
      if (error.message.contains('community_rate_limited')) {
        throw CommunityFailure(
          'Bạn đăng hơi nhanh. Hãy thử lại sau ít phút.',
          cause: error,
        );
      }
      if (error.code == '23505') {
        throw CommunityFailure('Bạn đã gửi báo cáo cho bài này.', cause: error);
      }
      throw CommunityFailure(
        'Máy chủ từ chối yêu cầu. Hãy thử lại sau.',
        cause: error,
      );
    } catch (error) {
      throw CommunityFailure(
        'Không kết nối được cộng đồng. Hãy kiểm tra mạng.',
        cause: error,
      );
    }
  }

  @override
  Future<List<CommunityPost>> fetchPosts({
    CommunityPostKind? kind,
    String search = '',
    DateTime? before,
    int limit = 20,
  }) {
    return _guard(() async {
      final client = _client;
      var query = client.from('community_posts').select(_postColumns);
      if (kind != null) query = query.eq('kind', kind.value);
      final term = search.trim().replaceAll(RegExp(r'[%,()]'), ' ');
      if (term.isNotEmpty) {
        query = query.or('title.ilike.%$term%,body.ilike.%$term%');
      }
      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
      }
      final rows = await query
          .order('created_at', ascending: false)
          .limit(limit);
      final posts = (rows as List)
          .whereType<Map>()
          .map((row) => mapPost(Map<String, dynamic>.from(row)))
          .toList();
      if (posts.isEmpty) return posts;

      final likes = await client
          .from('community_likes')
          .select('post_id')
          .eq('user_id', client.auth.currentUser!.id)
          .inFilter('post_id', posts.map((p) => p.id).toList());
      final liked = {
        for (final row in (likes as List).whereType<Map>()) '${row['post_id']}',
      };
      return [
        for (final post in posts)
          post.copyWith(likedByMe: liked.contains(post.id)),
      ];
    });
  }

  @override
  Future<CommunityPost> createPost(
    CommunityPostDraft draft, {
    required String authorName,
  }) {
    return _guard(() async {
      String? clean(String? value) {
        final text = value?.trim() ?? '';
        return text.isEmpty ? null : text;
      }

      final row = await _client
          .from('community_posts')
          .insert({
            'author_name': _authorName(authorName),
            'kind': draft.kind.value,
            'title': draft.title.trim(),
            'body': draft.body.trim(),
            'tags': draft.tags,
            'job_company': clean(draft.jobCompany),
            'job_location': clean(draft.jobLocation),
            'job_url': clean(draft.jobUrl),
            'job_salary': clean(draft.jobSalary),
          })
          .select(_postColumns)
          .single();
      return mapPost(row);
    });
  }

  @override
  Future<void> deletePost(String postId) => _guard(() async {
    await _client.from('community_posts').delete().eq('id', postId);
  });

  @override
  Future<List<CommunityComment>> fetchComments(String postId) {
    return _guard(() async {
      final rows = await _client
          .from('community_comments')
          .select('id, post_id, author_id, author_name, body, created_at')
          .eq('post_id', postId)
          .order('created_at')
          .limit(200);
      return (rows as List)
          .whereType<Map>()
          .map((row) => mapComment(Map<String, dynamic>.from(row)))
          .toList();
    });
  }

  @override
  Future<CommunityComment> addComment(
    String postId,
    String body, {
    required String authorName,
  }) {
    return _guard(() async {
      final row = await _client
          .from('community_comments')
          .insert({
            'post_id': postId,
            'author_name': _authorName(authorName),
            'body': body.trim(),
          })
          .select('id, post_id, author_id, author_name, body, created_at')
          .single();
      return mapComment(row);
    });
  }

  @override
  Future<void> deleteComment(String commentId) => _guard(() async {
    await _client.from('community_comments').delete().eq('id', commentId);
  });

  @override
  Future<bool> setLiked(String postId, {required bool liked}) {
    return _guard(() async {
      final client = _client;
      if (liked) {
        // ON CONFLICT DO NOTHING: likes are insert-only (no update grant).
        await client.from('community_likes').upsert({
          'post_id': postId,
          'user_id': client.auth.currentUser!.id,
        }, ignoreDuplicates: true);
      } else {
        await client
            .from('community_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', client.auth.currentUser!.id);
      }
      return liked;
    });
  }

  @override
  Future<void> report(String postId, String reason) => _guard(() async {
    await _client.from('community_reports').insert({
      'post_id': postId,
      'reason': reason.trim(),
    });
  });

  static String _authorName(String value) {
    final name = value.trim();
    if (name.isEmpty) return 'Thành viên';
    return name.length > 60 ? name.substring(0, 60) : name;
  }

  static CommunityPost mapPost(Map<String, dynamic> row) {
    String? text(Object? value) =>
        value is String && value.trim().isNotEmpty ? value : null;
    return CommunityPost(
      id: '${row['id']}',
      authorId: '${row['author_id']}',
      authorName: text(row['author_name']) ?? 'Thành viên',
      kind: CommunityPostKind.fromValue(row['kind'] as String?),
      title: '${row['title'] ?? ''}',
      body: '${row['body'] ?? ''}',
      createdAt:
          DateTime.tryParse('${row['created_at']}')?.toUtc() ??
          DateTime.now().toUtc(),
      tags: (row['tags'] as List?)?.whereType<String>().toList() ?? const [],
      jobCompany: text(row['job_company']),
      jobLocation: text(row['job_location']),
      jobUrl: text(row['job_url']),
      jobSalary: text(row['job_salary']),
      likeCount: (row['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (row['comment_count'] as num?)?.toInt() ?? 0,
    );
  }

  static CommunityComment mapComment(Map<String, dynamic> row) {
    return CommunityComment(
      id: '${row['id']}',
      postId: '${row['post_id']}',
      authorId: '${row['author_id']}',
      authorName: (row['author_name'] as String?) ?? 'Thành viên',
      body: '${row['body'] ?? ''}',
      createdAt:
          DateTime.tryParse('${row['created_at']}')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => SupabaseCommunityRepository(),
);
