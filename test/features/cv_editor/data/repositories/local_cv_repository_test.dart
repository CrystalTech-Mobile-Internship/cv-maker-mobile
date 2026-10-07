import 'dart:io';

import 'package:cv_maker_mobile/core/database/app_database.dart';
import 'package:cv_maker_mobile/features/cv_editor/data/repositories/local_cv_repository.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/repositories/cv_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late LocalCvRepository repository;

  group('LocalCvRepository', () {
    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = LocalCvRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('saves local changes as unsynced with a new UTC timestamp', () async {
      final original = _buildCv(
        id: 'cv-1',
        userId: 'user-1',
        isSynced: true,
        updatedAt: DateTime.utc(2026, 10, 6, 8),
      );
      final editedAt = DateTime.utc(2026, 10, 6, 9);

      final saved = await repository.save(original, now: editedAt);
      final loaded = await repository.getById(original.id);

      expect(saved.isSynced, isFalse);
      expect(saved.updatedAt, editedAt);
      expect(loaded?.isSynced, isFalse);
      expect(loaded?.updatedAt, editedAt);
      expect(loaded?.title, original.title);
    });

    test('can persist a synchronized cloud snapshot unchanged', () async {
      final cloudCv = _buildCv(
        id: 'cloud-cv',
        userId: 'user-1',
        isSynced: true,
        updatedAt: DateTime.utc(2026, 10, 6, 10),
      );

      await repository.save(cloudCv, markAsLocalChange: false);
      final loaded = await repository.getById(cloudCv.id);

      expect(loaded?.isSynced, isTrue);
      expect(loaded?.updatedAt, cloudCv.updatedAt);
    });

    test('returns CVs ordered by newest update first', () async {
      await repository.save(
        _buildCv(id: 'older', updatedAt: DateTime.utc(2026, 10, 6, 8)),
        markAsLocalChange: false,
      );
      await repository.save(
        _buildCv(id: 'newer', updatedAt: DateTime.utc(2026, 10, 6, 10)),
        markAsLocalChange: false,
      );

      final results = await repository.getAll();

      expect(results.map((cv) => cv.id), ['newer', 'older']);
    });

    test('filters pending sync records by authenticated user', () async {
      await repository.save(
        _buildCv(
          id: 'user-1-pending',
          userId: 'user-1',
          updatedAt: DateTime.utc(2026, 10, 6, 8),
        ),
        markAsLocalChange: false,
      );
      await repository.save(
        _buildCv(
          id: 'user-1-synced',
          userId: 'user-1',
          isSynced: true,
          updatedAt: DateTime.utc(2026, 10, 6, 9),
        ),
        markAsLocalChange: false,
      );
      await repository.save(
        _buildCv(
          id: 'user-2-pending',
          userId: 'user-2',
          updatedAt: DateTime.utc(2026, 10, 6, 10),
        ),
        markAsLocalChange: false,
      );
      await repository.save(
        _buildCv(id: 'guest-pending', updatedAt: DateTime.utc(2026, 10, 6, 11)),
        markAsLocalChange: false,
      );

      final pending = await repository.getPendingSync('user-1');

      expect(pending.map((cv) => cv.id), ['user-1-pending']);
    });

    test('duplicates a CV with a new identity and unsynced state', () async {
      final source = _buildCv(
        id: 'source',
        userId: 'user-1',
        isSynced: true,
        updatedAt: DateTime.utc(2026, 10, 6, 8),
      );
      final duplicatedAt = DateTime.utc(2026, 10, 6, 12);
      await repository.save(source, markAsLocalChange: false);

      final duplicate = await repository.duplicate(
        source.id,
        newId: 'copy',
        now: duplicatedAt,
      );

      expect(duplicate.id, 'copy');
      expect(duplicate.userId, source.userId);
      expect(duplicate.title, '${source.title} (Bản sao)');
      expect(duplicate.isSynced, isFalse);
      expect(duplicate.createdAt, duplicatedAt);
      expect(duplicate.updatedAt, duplicatedAt);
      expect(await repository.getById('source'), isNotNull);
      expect(await repository.getById('copy'), isNotNull);
    });

    test('throws a typed exception when duplicating a missing CV', () async {
      expect(
        () => repository.duplicate('missing', newId: 'copy'),
        throwsA(isA<CvNotFoundException>()),
      );
    });

    test('marks a CV as synced and queues account deletion', () async {
      await repository.save(
        _buildCv(id: 'cv-1', userId: 'user-1'),
        markAsLocalChange: false,
      );
      final deletedAt = DateTime.utc(2026, 10, 6, 14);

      expect(await repository.markSynced('cv-1'), isTrue);
      expect((await repository.getById('cv-1'))?.isSynced, isTrue);
      expect(await repository.deleteById('cv-1', now: deletedAt), isTrue);
      expect(await repository.getById('cv-1'), isNull);
      expect(await repository.deleteById('cv-1'), isFalse);

      final deletions = await repository.getPendingDeletions('user-1');
      expect(deletions, hasLength(1));
      expect(deletions.single.cvId, 'cv-1');
      expect(deletions.single.deletedAt, deletedAt);
      expect(await repository.confirmDeletionSynced('cv-1'), isTrue);
      expect(await repository.getPendingDeletions('user-1'), isEmpty);
    });

    test('deletes a guest CV without creating a cloud tombstone', () async {
      await repository.save(_buildCv(id: 'guest-cv'), markAsLocalChange: false);

      expect(await repository.deleteById('guest-cv'), isTrue);
      expect(await repository.getById('guest-cv'), isNull);
      expect(await repository.getPendingDeletions('user-1'), isEmpty);
    });
  });

  test('persists CV data after closing and reopening SQLite', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'smart_cv_database_test_',
    );
    final databaseFile = File('${tempDirectory.path}/smart_cv_test.sqlite');

    try {
      final firstDatabase = AppDatabase(NativeDatabase(databaseFile));
      final firstRepository = LocalCvRepository(firstDatabase);
      await firstRepository.save(
        _buildCv(
          id: 'persistent-cv',
          userId: 'user-1',
          updatedAt: DateTime.utc(2026, 10, 6, 13),
        ),
        markAsLocalChange: false,
      );
      await firstDatabase.close();

      final reopenedDatabase = AppDatabase(NativeDatabase(databaseFile));
      final reopenedRepository = LocalCvRepository(reopenedDatabase);
      final restored = await reopenedRepository.getById('persistent-cv');

      expect(restored?.id, 'persistent-cv');
      expect(restored?.personalInfo.fullName, 'Nguyễn Văn Mẫu');
      expect(restored?.updatedAt, DateTime.utc(2026, 10, 6, 13));

      await reopenedDatabase.close();
    } finally {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('migrates schema v1 by adding the cloud deletion queue', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'smart_cv_migration_test_',
    );
    final databaseFile = File('${tempDirectory.path}/smart_cv_v1.sqlite');

    try {
      final migratedDatabase = AppDatabase(
        NativeDatabase(
          databaseFile,
          setup: (sqlite) {
            sqlite.execute('''
              CREATE TABLE local_cvs (
                id TEXT NOT NULL PRIMARY KEY,
                user_id TEXT,
                title TEXT NOT NULL,
                template_id TEXT NOT NULL,
                payload_json TEXT NOT NULL,
                is_synced INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              )
            ''');
            sqlite.execute('PRAGMA user_version = 1');
          },
        ),
      );
      final migratedRepository = LocalCvRepository(migratedDatabase);

      await migratedRepository.save(
        _buildCv(id: 'migrated-cv', userId: 'user-1'),
        markAsLocalChange: false,
      );
      expect(await migratedRepository.deleteById('migrated-cv'), isTrue);
      expect(
        await migratedRepository.getPendingDeletions('user-1'),
        hasLength(1),
      );

      await migratedDatabase.close();
    } finally {
      await tempDirectory.delete(recursive: true);
    }
  });
}

CvModel _buildCv({
  required String id,
  String? userId,
  bool isSynced = false,
  DateTime? updatedAt,
}) {
  final timestamp = updatedAt ?? DateTime.utc(2026, 10, 6, 8);

  return CvModel(
    id: id,
    userId: userId,
    title: 'CV Flutter Developer',
    templateId: 'harvard_ats',
    primaryColor: '#1E293B',
    fontSizeScale: 1,
    personalInfo: const PersonalInfoModel(
      fullName: 'Nguyễn Văn Mẫu',
      targetRole: 'Flutter Developer',
      email: 'developer@example.com',
    ),
    summary: 'Ứng viên Flutter tập trung vào sản phẩm offline-first.',
    skills: const [
      SkillModel(
        id: 'skill-1',
        name: 'Flutter',
        category: SkillCategory.hard,
        proficiency: 85,
      ),
    ],
    isSynced: isSynced,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
