import '../models/cv_model.dart';

abstract interface class CvRepository {
  Stream<List<CvModel>> watchAll();

  Future<List<CvModel>> getAll();

  Future<CvModel?> getById(String id);

  Future<List<CvModel>> getPendingSync(String userId);

  Future<List<CvDeletionRequest>> getPendingDeletions(String userId);

  /// Saves [cv] locally. Local user edits are unsynced by default.
  Future<CvModel> save(
    CvModel cv, {
    bool markAsLocalChange = true,
    DateTime? now,
  });

  Future<CvModel> duplicate(
    String sourceId, {
    required String newId,
    DateTime? now,
  });

  Future<bool> markSynced(String id);

  Future<bool> deleteById(String id, {DateTime? now});

  Future<bool> confirmDeletionSynced(String id);
}

final class CvDeletionRequest {
  const CvDeletionRequest({
    required this.cvId,
    required this.userId,
    required this.deletedAt,
  });

  final String cvId;
  final String userId;
  final DateTime deletedAt;
}

final class CvNotFoundException implements Exception {
  const CvNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'CvNotFoundException: CV "$id" was not found.';
}
