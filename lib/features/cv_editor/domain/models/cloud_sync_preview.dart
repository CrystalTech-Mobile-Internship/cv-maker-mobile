/// Domain model representing the pre-sync preview calculation.
///
/// Gives users complete transparency into upcoming cloud actions
/// (uploads, downloads, deletions, and conflicts) before any data mutation occurs.
class CloudSyncPreview {
  const CloudSyncPreview({
    required this.targetBackend,
    required this.userEmail,
    required this.pendingUploadCount,
    required this.pendingDownloadCount,
    required this.conflictCount,
    required this.pendingDeletionCount,
    required this.localCvCount,
    required this.remoteCvCount,
    this.errorMessage,
  });

  final String targetBackend;
  final String userEmail;
  final int pendingUploadCount;
  final int pendingDownloadCount;
  final int conflictCount;
  final int pendingDeletionCount;
  final int localCvCount;
  final int remoteCvCount;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  bool get hasChanges =>
      pendingUploadCount > 0 ||
      pendingDownloadCount > 0 ||
      conflictCount > 0 ||
      pendingDeletionCount > 0;

  bool get hasDeletionsOrOverwrites =>
      pendingDeletionCount > 0 || conflictCount > 0;

  int get totalOperations =>
      pendingUploadCount +
      pendingDownloadCount +
      conflictCount +
      pendingDeletionCount;
}
