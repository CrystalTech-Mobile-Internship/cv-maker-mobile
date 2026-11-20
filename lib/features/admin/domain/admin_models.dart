/// Data shown on the admin page. Every call is checked again on the server,
/// so these models never decide who is an admin.
library;

import '../../support/domain/support_models.dart';

DateTime _time(Object? value) =>
    DateTime.tryParse('$value')?.toUtc() ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

DateTime? _optionalTime(Object? value) =>
    value == null ? null : DateTime.tryParse('$value')?.toUtc();

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

String _text(Object? value) => value == null ? '' : '$value';

/// Totals at the top of the page.
class AdminStats {
  const AdminStats({
    required this.users,
    required this.proUsers,
    required this.monthRevenue,
    required this.waitingThreads,
    required this.pendingRequests,
  });

  final int users;
  final int proUsers;
  final int monthRevenue;
  final int waitingThreads;
  final int pendingRequests;

  factory AdminStats.fromRow(Map<String, dynamic> row) => AdminStats(
    users: _int(row['users']),
    proUsers: _int(row['pro_users']),
    monthRevenue: _int(row['month_revenue']),
    waitingThreads: _int(row['waiting_threads']),
    pendingRequests: _int(row['pending_requests']),
  );
}

/// One account's support conversation in the inbox list.
class SupportThread {
  const SupportThread({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.lastBody,
    required this.lastFromSupport,
    required this.lastAt,
    required this.waiting,
    int? unread,
  }) : unread = unread ?? waiting;

  final String userId;
  final String displayName;
  final String email;
  final String lastBody;
  final bool lastFromSupport;
  final DateTime lastAt;

  /// User messages sent after the last reply.
  final int waiting;

  /// User messages support has not opened yet.
  final int unread;

  bool get needsReply => waiting > 0;

  bool get hasUnread => unread > 0;

  factory SupportThread.fromRow(Map<String, dynamic> row) => SupportThread(
    userId: _text(row['user_id']),
    displayName: _text(row['display_name']),
    email: _text(row['email']),
    lastBody: _text(row['last_body']),
    lastFromSupport: row['last_sender'] == 'support',
    lastAt: _time(row['last_at']),
    waiting: _int(row['waiting']),
    unread: row.containsKey('unread') ? _int(row['unread']) : null,
  );
}

/// A Pro checkout started by a user.
class AdminProRequest {
  const AdminProRequest({
    required this.id,
    required this.email,
    required this.plan,
    required this.amount,
    required this.transferCode,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  final String id;
  final String email;
  final String plan;
  final int amount;
  final String transferCode;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;

  bool get isPending => status == 'pending';

  factory AdminProRequest.fromRow(Map<String, dynamic> row) => AdminProRequest(
    id: _text(row['id']),
    email: _text(row['email']),
    plan: _text(row['plan']),
    amount: _int(row['amount']),
    transferCode: _text(row['transfer_code']),
    status: _text(row['status']),
    createdAt: _time(row['created_at']),
    paidAt: _optionalTime(row['paid_at']),
  );
}

/// A bank transfer reported by SePay.
class AdminPaymentEvent {
  const AdminPaymentEvent({
    required this.id,
    required this.amount,
    required this.content,
    required this.status,
    required this.createdAt,
    this.requestId,
  });

  final String id;
  final int amount;
  final String content;

  /// matched, unmatched, ignored or received.
  final String status;
  final DateTime createdAt;
  final String? requestId;

  factory AdminPaymentEvent.fromRow(Map<String, dynamic> row) =>
      AdminPaymentEvent(
        id: _text(row['id']),
        amount: _int(row['amount']),
        content: _text(row['content']),
        status: _text(row['status']),
        createdAt: _time(row['created_at']),
        requestId: row['request_id'] == null ? null : '${row['request_id']}',
      );
}

class AdminFailure implements Exception {
  const AdminFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AdminRepository {
  /// Whether the signed-in account is an admin (false when signed out).
  Future<bool> isAdmin();

  Future<AdminStats> stats();

  Future<List<SupportThread>> threads();

  /// Fires whenever any support message is added, so lists can refresh.
  Stream<void> supportChanges();

  /// One account's conversation, oldest first, kept live.
  Stream<List<SupportMessage>> conversation(String userId);

  Future<void> reply(String userId, String body);

  /// Records that support opened this conversation.
  Future<void> markRead(String userId);

  Future<List<AdminProRequest>> proRequests();

  Future<List<AdminPaymentEvent>> paymentEvents();

  Future<void> reviewProRequest(String requestId, {required bool approve});
}
