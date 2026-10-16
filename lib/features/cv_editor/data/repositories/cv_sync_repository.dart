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
       _remoteDataSource = remoteDataSource ?? CvRemoteDataSource();

  final CvRepository _localRepository;
  final CvRemoteDataSource _remoteDataSource;

  /// Saves [cv] to local SQLite first (offline guarantee).
  ///
  /// If [userId] is present (user is logged in), attempts to upsert the CV
  /// to Supabase Cloud and marks it as synced locally upon success.
  Future<CvSaveResult> saveAndSync(CvModel cv, {String? userId}) async {
    // 1. Always persist to SQLite locally first (Offline-First guarantee)
    final savedLocal = await _localRepository.save(cv);

    // 2. If guest or no user, return local success immediately
    if (userId == null || userId.isEmpty) {
      return CvSaveResult(savedCv: savedLocal, isSynced: false);
    }

    // 3. If signed in, sync to Supabase Cloud
    try {
      final remoteCv = await _remoteDataSource.upsertCv(savedLocal);
      await _localRepository.markSynced(savedLocal.id);
      return CvSaveResult(savedCv: remoteCv, isSynced: true);
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
}
