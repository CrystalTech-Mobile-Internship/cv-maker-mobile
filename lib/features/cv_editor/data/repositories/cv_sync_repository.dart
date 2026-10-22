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
    this.errorMessage,
  });

  final int uploadedCount;
  final int downloadedCount;
  final int failedCount;
  final String? errorMessage;

  bool get isSuccess => failedCount == 0 && errorMessage == null;
  int get synchronizedCount => uploadedCount + downloadedCount;
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

  /// Uploads unsynchronized local and guest CVs, then downloads the current
  /// account's cloud CVs into SQLite. Each local draft remains intact when an
  /// individual cloud operation fails.
  Future<CvSyncResult> syncAccount(String userId) async {
    if (userId.isEmpty) {
      return const CvSyncResult(
        uploadedCount: 0,
        downloadedCount: 0,
        failedCount: 1,
        errorMessage: 'Cần đăng nhập trước khi đồng bộ.',
      );
    }

    var uploaded = 0;
    var failed = 0;
    final pending = await _localRepository.getPendingSync(userId);
    for (final cv in pending) {
      try {
        final remoteCv = await _remote.upsertCv(cv.copyWith(userId: userId));
        await _localRepository.replaceWithSynced(
          cv.id,
          remoteCv.copyWith(userId: userId, isSynced: true),
        );
        uploaded++;
      } catch (_) {
        failed++;
      }
    }

    try {
      final remoteCvs = await _remote.fetchUserCvs();
      for (final cv in remoteCvs) {
        await _localRepository.save(
          cv.copyWith(userId: userId, isSynced: true),
          markAsLocalChange: false,
        );
      }
      return CvSyncResult(
        uploadedCount: uploaded,
        downloadedCount: remoteCvs.length,
        failedCount: failed,
        errorMessage: failed == 0
            ? null
            : '$failed CV chưa thể tải lên. Bản local vẫn an toàn.',
      );
    } on CvRemoteDataSourceException catch (error) {
      return CvSyncResult(
        uploadedCount: uploaded,
        downloadedCount: 0,
        failedCount: failed + 1,
        errorMessage: error.message,
      );
    } catch (_) {
      return CvSyncResult(
        uploadedCount: uploaded,
        downloadedCount: 0,
        failedCount: failed + 1,
        errorMessage: 'Không thể tải dữ liệu cloud. CV local vẫn an toàn.',
      );
    }
  }
}
