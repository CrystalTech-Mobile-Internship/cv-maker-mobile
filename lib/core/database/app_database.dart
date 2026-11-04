import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('LocalCvRow')
class LocalCvs extends Table {
  TextColumn get id => text()();

  TextColumn get userId => text().nullable()();

  TextColumn get title => text()();

  TextColumn get templateId => text()();

  TextColumn get payloadJson => text()();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PendingCvDeletionRow')
class PendingCvDeletions extends Table {
  TextColumn get cvId => text()();

  TextColumn get userId => text()();

  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {cvId};
}

@DriftDatabase(tables: [LocalCvs, PendingCvDeletions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults()
    : super(
        driftDatabase(
          name: 'smart_cv_maker',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.createTable(pendingCvDeletions);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Stream<List<LocalCvRow>> watchAllCvs() {
    return (select(
      localCvs,
    )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).watch();
  }

  Future<List<LocalCvRow>> getAllCvs() {
    return (select(
      localCvs,
    )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).get();
  }

  Future<LocalCvRow?> getCvById(String id) {
    return (select(
      localCvs,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<List<LocalCvRow>> getPendingSyncCvs(String userId) {
    return (select(localCvs)
          ..where(
            (row) =>
                (row.userId.isNull() | row.userId.equals(userId)) &
                row.isSynced.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]))
        .get();
  }

  Future<void> upsertCv(LocalCvsCompanion cv) {
    return into(localCvs).insertOnConflictUpdate(cv);
  }

  Future<void> replaceCv(String localId, LocalCvsCompanion syncedCv) {
    return transaction(() async {
      await (delete(localCvs)..where((row) => row.id.equals(localId))).go();
      await into(localCvs).insertOnConflictUpdate(syncedCv);
    });
  }

  Future<List<PendingCvDeletionRow>> getPendingCvDeletions(String userId) {
    return (select(pendingCvDeletions)
          ..where((row) => row.userId.equals(userId))
          ..orderBy([(row) => OrderingTerm.asc(row.deletedAt)]))
        .get();
  }

  Future<bool> deleteCvAndQueueRemoteDeletion(
    String id, {
    required DateTime deletedAt,
  }) {
    return transaction(() async {
      final existing = await getCvById(id);
      if (existing == null) {
        return false;
      }

      final userId = existing.userId;
      if (userId != null) {
        await into(pendingCvDeletions).insertOnConflictUpdate(
          PendingCvDeletionsCompanion.insert(
            cvId: id,
            userId: userId,
            deletedAt: deletedAt.toUtc(),
          ),
        );
      }

      await (delete(localCvs)..where((row) => row.id.equals(id))).go();
      return true;
    });
  }

  Future<bool> deletePendingCvDeletion(String cvId) async {
    final deletedRows = await (delete(
      pendingCvDeletions,
    )..where((row) => row.cvId.equals(cvId))).go();

    return deletedRows > 0;
  }

  Future<bool> setCvSyncState(String id, {required bool isSynced}) async {
    final updatedRows =
        await (update(localCvs)..where((row) => row.id.equals(id))).write(
          LocalCvsCompanion(isSynced: Value(isSynced)),
        );

    return updatedRows > 0;
  }
}
