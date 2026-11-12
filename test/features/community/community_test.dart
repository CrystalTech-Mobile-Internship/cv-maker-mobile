import 'package:cv_maker_mobile/features/auth/domain/models/auth_user.dart';
import 'package:cv_maker_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:cv_maker_mobile/features/community/data/repositories/supabase_community_repository.dart';
import 'package:cv_maker_mobile/features/community/domain/models/community_models.dart';
import 'package:cv_maker_mobile/features/community/domain/repositories/community_repository.dart';
import 'package:cv_maker_mobile/features/community/presentation/controllers/community_feed_controller.dart';
import 'package:cv_maker_mobile/features/community/presentation/screens/community_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CommunityPost _post(
  String id, {
  CommunityPostKind kind = CommunityPostKind.job,
}) => CommunityPost(
  id: id,
  authorId: 'author',
  authorName: 'Lan',
  kind: kind,
  title: 'Tuyển Flutter Intern $id',
  body: 'Mô tả công việc cho vị trí thực tập Flutter.',
  createdAt: DateTime.utc(2026, 11, 10),
  jobCompany: 'CrystalTech',
  jobLocation: 'Hà Nội',
);

class _FakeRepository implements CommunityRepository {
  _FakeRepository(this.posts);

  final List<CommunityPost> posts;
  CommunityPostKind? lastKind;
  bool failLike = false;

  @override
  Future<List<CommunityPost>> fetchPosts({
    CommunityPostKind? kind,
    String search = '',
    DateTime? before,
    int limit = 20,
  }) async {
    lastKind = kind;
    return posts
        .where((p) => kind == null || p.kind == kind)
        .where((p) => p.title.contains(search))
        .toList();
  }

  @override
  Future<bool> setLiked(String postId, {required bool liked}) async {
    if (failLike) throw const CommunityFailure('Lỗi mạng');
    return liked;
  }

  @override
  Future<CommunityPost> createPost(
    CommunityPostDraft draft, {
    required String authorName,
  }) => throw UnimplementedError();

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<List<CommunityComment>> fetchComments(String postId) async => [];

  @override
  Future<CommunityComment> addComment(
    String postId,
    String body, {
    required String authorName,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteComment(String commentId) async {}

  @override
  Future<void> report(String postId, String reason) async {}
}

void main() {
  group('CommunityPostDraft', () {
    test('requires a company for job posts and a valid URL', () {
      expect(
        const CommunityPostDraft(
          kind: CommunityPostKind.job,
          title: 'Tuyển dev',
          body: 'Mô tả công việc chi tiết',
        ).validate(),
        contains('công ty'),
      );
      expect(
        const CommunityPostDraft(
          kind: CommunityPostKind.job,
          title: 'Tuyển dev',
          body: 'Mô tả công việc chi tiết',
          jobCompany: 'A',
          jobUrl: 'javascript:alert(1)',
        ).validate(),
        contains('http'),
      );
      expect(
        const CommunityPostDraft(
          kind: CommunityPostKind.discussion,
          title: 'Kinh nghiệm phỏng vấn',
          body: 'Chia sẻ một vài kinh nghiệm',
        ).validate(),
        isNull,
      );
    });

    test('detects personal contact details', () {
      expect(
        const CommunityPostDraft(
          kind: CommunityPostKind.cvReview,
          title: 'Nhờ góp ý CV',
          body: 'Liên hệ mình qua 0901 234 567 nhé',
        ).containsContactDetails,
        isTrue,
      );
      expect(
        const CommunityPostDraft(
          kind: CommunityPostKind.cvReview,
          title: 'Nhờ góp ý CV',
          body: 'Mình ứng tuyển Flutter intern',
        ).containsContactDetails,
        isFalse,
      );
    });
  });

  group('CommunityFeedController', () {
    test('filters by kind and toggles likes optimistically', () async {
      final repository = _FakeRepository([
        _post('1'),
        _post('2', kind: CommunityPostKind.discussion),
      ]);
      final controller = CommunityFeedController(repository);

      await controller.setKind(CommunityPostKind.job);
      expect(controller.state.posts.map((p) => p.id), ['1']);
      expect(repository.lastKind, CommunityPostKind.job);

      await controller.toggleLike(controller.state.posts.first);
      expect(controller.state.posts.first.likedByMe, isTrue);
      expect(controller.state.posts.first.likeCount, 1);
    });

    test('reverts a like when the server rejects it', () async {
      final repository = _FakeRepository([_post('1')])..failLike = true;
      final controller = CommunityFeedController(repository);
      await controller.refresh();

      await controller.toggleLike(controller.state.posts.first);

      expect(controller.state.posts.first.likedByMe, isFalse);
      expect(controller.state.errorMessage, 'Lỗi mạng');
    });
  });

  group('CommunityView', () {
    testWidgets('asks guests to sign in', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentAuthUserProvider.overrideWithValue(null)],
          child: const MaterialApp(home: Scaffold(body: CommunityView())),
        ),
      );
      expect(find.text('Cộng đồng việc làm'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
    });

    testWidgets('lists posts for signed-in users', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAuthUserProvider.overrideWithValue(
              const AuthUser(
                id: 'me',
                email: 'me@example.com',
                displayName: 'Me',
                provider: 'email',
                isEmailConfirmed: true,
              ),
            ),
            communityRepositoryProvider.overrideWithValue(
              _FakeRepository([_post('1')]),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: CommunityView())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tuyển Flutter Intern 1'), findsOneWidget);
      expect(find.text('CrystalTech · Hà Nội'), findsOneWidget);
      expect(find.text('Việc làm'), findsWidgets);
    });
  });
}
