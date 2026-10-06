import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/cv_model.dart';
import '../../domain/repositories/cv_repository.dart';

final class LocalCvRepository implements CvRepository {
  LocalCvRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<CvModel>> watchAll() {
    return _database.watchAllCvs().map(_rowsToModels);
  }

  @override
  Future<List<CvModel>> getAll() async {
    return _rowsToModels(await _database.getAllCvs());
  }

  @override
  Future<CvModel?> getById(String id) async {
    final row = await _database.getCvById(id);
    return row == null ? null : _rowToModel(row);
  }

  @override
  Future<List<CvModel>> getPendingSync(String userId) async {
    return _rowsToModels(await _database.getPendingSyncCvs(userId));
  }

  @override
  Future<List<CvDeletionRequest>> getPendingDeletions(String userId) async {
    final rows = await _database.getPendingCvDeletions(userId);
    return rows
        .map(
          (row) => CvDeletionRequest(
            cvId: row.cvId,
            userId: row.userId,
            deletedAt: row.deletedAt.toUtc(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<CvModel> save(
    CvModel cv, {
    bool markAsLocalChange = true,
    DateTime? now,
  }) async {
    final savedCv = markAsLocalChange
        ? cv.copyWith(
            isSynced: false,
            updatedAt: (now ?? DateTime.now()).toUtc(),
          )
        : cv;

    await _database.upsertCv(_toCompanion(savedCv));
    return savedCv;
  }

  @override
  Future<CvModel> duplicate(
    String sourceId, {
    required String newId,
    DateTime? now,
  }) async {
    final source = await getById(sourceId);
    if (source == null) {
      throw CvNotFoundException(sourceId);
    }

    final timestamp = (now ?? DateTime.now()).toUtc();
    final duplicate = source.copyWith(
      id: newId,
      title: '${source.title} (Bản sao)',
      isSynced: false,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    await _database.upsertCv(_toCompanion(duplicate));
    return duplicate;
  }

  @override
  Future<bool> markSynced(String id) {
    return _database.setCvSyncState(id, isSynced: true);
  }

  @override
  Future<bool> deleteById(String id, {DateTime? now}) {
    return _database.deleteCvAndQueueRemoteDeletion(
      id,
      deletedAt: (now ?? DateTime.now()).toUtc(),
    );
  }

  @override
  Future<bool> confirmDeletionSynced(String id) {
    return _database.deletePendingCvDeletion(id);
  }

  List<CvModel> _rowsToModels(List<LocalCvRow> rows) {
    return rows.map(_rowToModel).toList(growable: false);
  }

  CvModel _rowToModel(LocalCvRow row) {
    try {
      final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
      return CvModel.fromJson(payload).copyWith(
        id: row.id,
        userId: row.userId,
        title: row.title,
        templateId: row.templateId,
        isSynced: row.isSynced,
        createdAt: row.createdAt.toUtc(),
        updatedAt: row.updatedAt.toUtc(),
      );
    } on Object catch (error) {
      throw FormatException('Invalid local CV payload for "${row.id}".', error);
    }
  }

  LocalCvsCompanion _toCompanion(CvModel cv) {
    return LocalCvsCompanion.insert(
      id: cv.id,
      userId: Value(cv.userId),
      title: cv.title,
      templateId: cv.templateId,
      payloadJson: jsonEncode(cv.toJson()),
      isSynced: Value(cv.isSynced),
      createdAt: cv.createdAt.toUtc(),
      updatedAt: cv.updatedAt.toUtc(),
    );
  }
}
