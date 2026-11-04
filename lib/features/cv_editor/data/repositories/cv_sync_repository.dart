import '../../domain/models/cloud_sync_preview.dart';
import '../../domain/models/cv_model.dart';
import '../../domain/repositories/cv_repository.dart';
import '../datasources/cv_remote_data_source.dart';

/// Result object returned by [CvSyncRepository.saveAndSync].
///
/// Encapsulates local persistence status, cloud synchronization status,
/// and any error messages without exposing backend implementation details to UI.
class CvSaveResult {
  const CvSaveResult({
    required this.savedCv,
    required this.isSynced,
    this.errorMessage,
  });

  final CvModel savedCv;
  final bool isSynced;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

class CvSyncResult {
  const CvSyncResult({
    required this.uploadedCount,
    required this.downloadedCount,
    required this.failedCount,
    this.deletedCount = 0,
    this.conflictCount = 0,
    this.errorMessage,
  });

  final int uploadedCount;
  final int downloadedCount;
  final int failedCount;
  final int deletedCount;
  final int conflictCount;
  final String? errorMessage;

  bool get isSuccess => failedCount == 0 && errorMessage == null;
  int get synchronizedCount => uploadedCount + downloadedCount + deletedCount;
}

/// Repository responsible for coordinating Local-First SQLite persistence
/// and remote Supabase Cloud synchronization.
///
/// This cleanly decouples the Presentation layer from knowing about
/// [CvRemoteDataSource] or network APIs.
class CvSyncRepository {
  CvSyncRepository({
    required CvRepository localRepository,
    CvRemoteDataSource? remoteDataSource,
  }) : _localRepository = localRepository,
       _remoteDataSource = remoteDataSource;

  final CvRepository _localRepository;
  final CvRemoteDataSource? _remoteDataSource;

  CvRemoteDataSource get _remote => _remoteDataSource ?? CvRemoteDataSource();

  /// Saves [cv] to local SQLite first (offline guarantee).
  ///
  /// If [userId] is present (user is logged in), attempts to upsert the CV
  /// to Supabase Cloud and marks it as synced locally upon success.
  Future<CvSaveResult> saveAndSync(CvModel cv, {String? userId}) async {
    // 1. Always persist to SQLite locally first (Offline-First guarantee)
    final localSnapshot = userId == null || userId.isEmpty
        ? cv
        : cv.copyWith(userId: userId);
    final savedLocal = await _localRepository.save(localSnapshot);

    // 2. If guest or no user, return local success immediately
    if (userId == null || userId.isEmpty) {
      return CvSaveResult(savedCv: savedLocal, isSynced: false);
    }

    // 3. If signed in, sync to Supabase Cloud
    try {
      final remoteCv = await _remote.upsertCv(savedLocal);
      final canonical = await _localRepository.replaceWithSynced(
        savedLocal.id,
        remoteCv.copyWith(userId: userId, isSynced: true),
      );
      return CvSaveResult(savedCv: canonical, isSynced: true);
    } on CvRemoteDataSourceException catch (error) {
      return CvSaveResult(
        savedCv: savedLocal,
        isSynced: false,
        errorMessage: error.message,
      );
    } catch (_) {
      return CvSaveResult(
        savedCv: savedLocal,
        isSynced: false,
        errorMessage: 'Lỗi kết nối khi đồng bộ lên máy chủ đám mây.',
      );
    }
  }

  /// Reconciles SQLite and Supabase using a last-write-wins strategy based on
  /// UTC [CvModel.updatedAt]. Cloud data is fetched before any upload so an
  /// older local draft can never overwrite a newer version from another
  /// device. Pending offline deletions are handled with the same rule.
  Future<CvSyncResult> syncAccount(String userId) async {
    if (userId.isEmpty) {
      return const CvSyncResult(
        uploadedCount: 0,
        downloadedCount: 0,
        failedCount: 1,
        errorMessage: 'Cần đăng nhập trước khi đồng bộ.',
      );
    }

    try {
      final remoteCvs = await _remote.fetchUserCvs();
      final remoteById = {for (final cv in remoteCvs) cv.id: cv};
      var uploaded = 0;
      var downloaded = 0;
      var deleted = 0;
      var conflicts = 0;
      var failed = 0;

      final pendingDeletions = await _localRepository.getPendingDeletions(
        userId,
      );
      for (final deletion in pendingDeletions) {
        final remoteCv = remoteById.remove(deletion.cvId);
        try {
          if (remoteCv != null &&
              remoteCv.updatedAt.isAfter(deletion.deletedAt)) {
            await _storeRemote(remoteCv, userId);
            downloaded++;
            conflicts++;
          } else {
            if (remoteCv != null) {
              await _remote.deleteRemoteCv(deletion.cvId);
            }
            deleted++;
          }
          await _localRepository.confirmDeletionSynced(deletion.cvId);
        } catch (_) {
          failed++;
        }
      }

      final pending = await _localRepository.getPendingSync(userId);
      for (final localCv in pending) {
        final remoteCv = remoteById.remove(localCv.id);
        if (remoteCv != null && remoteCv.updatedAt.isAfter(localCv.updatedAt)) {
          try {
            await _storeRemote(remoteCv, userId);
            downloaded++;
            conflicts++;
          } catch (_) {
            failed++;
          }
          continue;
        }

        try {
          final uploadedCv = await _remote.upsertCv(
            localCv.copyWith(userId: userId),
          );
          await _localRepository.replaceWithSynced(
            localCv.id,
            uploadedCv.copyWith(userId: userId, isSynced: true),
          );
          remoteById.remove(uploadedCv.id);
          uploaded++;
          if (remoteCv != null) conflicts++;
        } catch (_) {
          failed++;
        }
      }

      for (final remoteCv in remoteById.values) {
        final localCv = await _localRepository.getById(remoteCv.id);
        final belongsToAnotherAccount =
            localCv?.userId != null && localCv?.userId != userId;
        if (belongsToAnotherAccount) continue;
        if (localCv == null || remoteCv.updatedAt.isAfter(localCv.updatedAt)) {
          try {
            await _storeRemote(remoteCv, userId);
            downloaded++;
          } catch (_) {
            failed++;
          }
        }
      }

      return CvSyncResult(
        uploadedCount: uploaded,
        downloadedCount: downloaded,
        deletedCount: deleted,
        conflictCount: conflicts,
        failedCount: failed,
        errorMessage: failed == 0
            ? null
            : '$failed thao tác chưa thể đồng bộ. Dữ liệu local vẫn an toàn.',
      );
    } on CvRemoteDataSourceException catch (error) {
      return CvSyncResult(
        uploadedCount: 0,
        downloadedCount: 0,
        failedCount: 1,
        errorMessage: error.message,
      );
    } catch (_) {
      return CvSyncResult(
        uploadedCount: 0,
        downloadedCount: 0,
        failedCount: 1,
        errorMessage: 'Không thể tải dữ liệu cloud. CV local vẫn an toàn.',
      );
    }
  }

  Future<void> _storeRemote(CvModel cv, String userId) {
    return _localRepository.save(
      cv.copyWith(userId: userId, isSynced: true),
      markAsLocalChange: false,
    );
  }

  /// Inspects remote cloud and local database to preview sync changes
  /// in a completely read-only manner (no data mutations).
  Future<CloudSyncPreview> inspectSyncPreview({
    required String userId,
    required String userEmail,
    required String backendLabel,
  }) async {
    if (userId.isEmpty) {
      return CloudSyncPreview(
        targetBackend: backendLabel,
        userEmail: userEmail,
        pendingUploadCount: 0,
        pendingDownloadCount: 0,
        conflictCount: 0,
        pendingDeletionCount: 0,
        localCvCount: 0,
        remoteCvCount: 0,
        errorMessage: 'Cần đăng nhập trước khi xem trước đồng bộ.',
      );
    }

    try {
      final remoteCvs = await _remote.fetchUserCvs();
      final remoteById = {for (final cv in remoteCvs) cv.id: cv};
      final localCvs = await _localRepository.getAll();
      final pendingDeletions = await _localRepository.getPendingDeletions(userId);
      final pendingLocal = await _localRepository.getPendingSync(userId);

      var uploadCount = 0;
      var downloadCount = 0;
      var conflictCount = 0;
      var deletionCount = 0;

      for (final deletion in pendingDeletions) {
        final remoteCv = remoteById[deletion.cvId];
        if (remoteCv != null) {
          if (remoteCv.updatedAt.isAfter(deletion.deletedAt)) {
            downloadCount++;
            conflictCount++;
          } else {
            deletionCount++;
          }
        }
      }

      for (final localCv in pendingLocal) {
        final remoteCv = remoteById[localCv.id];
        if (remoteCv != null) {
          if (remoteCv.updatedAt.isAfter(localCv.updatedAt)) {
            downloadCount++;
            conflictCount++;
          } else {
            uploadCount++;
            conflictCount++;
          }
        } else {
          uploadCount++;
        }
      }

      final pendingLocalIds = pendingLocal.map((c) => c.id).toSet();
      final pendingDeletionIds = pendingDeletions.map((d) => d.cvId).toSet();

      for (final remoteCv in remoteCvs) {
        if (pendingLocalIds.contains(remoteCv.id) || pendingDeletionIds.contains(remoteCv.id)) {
          continue;
        }
        final localCv = await _localRepository.getById(remoteCv.id);
        if (localCv == null || remoteCv.updatedAt.isAfter(localCv.updatedAt)) {
          downloadCount++;
        }
      }

      return CloudSyncPreview(
        targetBackend: backendLabel,
        userEmail: userEmail,
        pendingUploadCount: uploadCount,
        pendingDownloadCount: downloadCount,
        conflictCount: conflictCount,
        pendingDeletionCount: deletionCount,
        localCvCount: localCvs.length,
        remoteCvCount: remoteCvs.length,
      );
    } on CvRemoteDataSourceException catch (error) {
      return CloudSyncPreview(
        targetBackend: backendLabel,
        userEmail: userEmail,
        pendingUploadCount: 0,
        pendingDownloadCount: 0,
        conflictCount: 0,
        pendingDeletionCount: 0,
        localCvCount: 0,
        remoteCvCount: 0,
        errorMessage: error.message,
      );
    } catch (_) {
      return CloudSyncPreview(
        targetBackend: backendLabel,
        userEmail: userEmail,
        pendingUploadCount: 0,
        pendingDownloadCount: 0,
        conflictCount: 0,
        pendingDeletionCount: 0,
        localCvCount: 0,
        remoteCvCount: 0,
        errorMessage: 'Không thể kết nối máy chủ để xem trước thay đổi.',
      );
    }
  }

}
