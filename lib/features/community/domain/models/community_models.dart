enum CommunityPostKind {
  discussion('discussion', 'Thảo luận'),
  job('job', 'Việc làm'),
  cvReview('cv_review', 'Góp ý CV');

  const CommunityPostKind(this.value, this.label);

  final String value;
  final String label;

  static CommunityPostKind fromValue(String? value) =>
      CommunityPostKind.values.firstWhere(
        (kind) => kind.value == value,
        orElse: () => CommunityPostKind.discussion,
      );
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.tags = const [],
    this.jobCompany,
    this.jobLocation,
    this.jobUrl,
    this.jobSalary,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final CommunityPostKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final List<String> tags;
  final String? jobCompany;
  final String? jobLocation;
  final String? jobUrl;
  final String? jobSalary;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  CommunityPost copyWith({int? likeCount, int? commentCount, bool? likedByMe}) {
    return CommunityPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      kind: kind,
      title: title,
      body: body,
      createdAt: createdAt,
      tags: tags,
      jobCompany: jobCompany,
      jobLocation: jobLocation,
      jobUrl: jobUrl,
      jobSalary: jobSalary,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;
}

/// Input for a new post; validated before it reaches the backend.
class CommunityPostDraft {
  const CommunityPostDraft({
    required this.kind,
    required this.title,
    required this.body,
    this.tags = const [],
    this.jobCompany,
    this.jobLocation,
    this.jobUrl,
    this.jobSalary,
  });

  final CommunityPostKind kind;
  final String title;
  final String body;
  final List<String> tags;
  final String? jobCompany;
  final String? jobLocation;
  final String? jobUrl;
  final String? jobSalary;

  /// Returns a user-facing error, or null when the draft is valid.
  String? validate() {
    final t = title.trim();
    final b = body.trim();
    if (t.length < 5 || t.length > 140) {
      return 'Tiêu đề cần từ 5 đến 140 ký tự.';
    }
    if (b.length < 10 || b.length > 4000) {
      return 'Nội dung cần từ 10 đến 4000 ký tự.';
    }
    if (tags.length > 5) return 'Tối đa 5 thẻ.';
    final url = jobUrl?.trim() ?? '';
    if (url.isNotEmpty && !RegExp(r'^https?://\S+$').hasMatch(url)) {
      return 'Đường dẫn ứng tuyển phải bắt đầu bằng http:// hoặc https://';
    }
    if (kind == CommunityPostKind.job && (jobCompany?.trim() ?? '').isEmpty) {
      return 'Bài chia sẻ việc làm cần tên công ty.';
    }
    return null;
  }

  /// Detects personal contact details the author may not want public.
  bool get containsContactDetails {
    final text = '$title\n$body';
    final email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
    final phone = RegExp(r'(\+?84|0)[\s.-]?\d{2,3}[\s.-]?\d{3}[\s.-]?\d{3,4}');
    return email.hasMatch(text) || phone.hasMatch(text);
  }
}
