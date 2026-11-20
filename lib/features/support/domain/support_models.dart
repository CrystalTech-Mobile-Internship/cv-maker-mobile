/// One message in the account's support conversation.
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.fromSupport,
    required this.body,
    required this.createdAt,
  });

  final String id;

  /// True for replies from the support team.
  final bool fromSupport;
  final String body;
  final DateTime createdAt;

  factory SupportMessage.fromRow(Map<String, dynamic> row) => SupportMessage(
    id: '${row['id']}',
    fromSupport: row['sender'] == 'support',
    body: '${row['body'] ?? ''}',
    createdAt:
        DateTime.tryParse('${row['created_at']}')?.toUtc() ??
        DateTime.now().toUtc(),
  );
}

class SupportFailure implements Exception {
  const SupportFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class SupportRepository {
  /// The signed-in account's conversation, oldest first, kept live.
  Stream<List<SupportMessage>> watch();

  /// When support last opened this conversation, kept live (null: never).
  Stream<DateTime?> watchSeenAt();

  /// Saves the message for this account and notifies the support inbox.
  Future<void> send(String body);
}
