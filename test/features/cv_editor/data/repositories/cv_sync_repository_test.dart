import 'package:cv_maker_mobile/core/database/app_database.dart';
import 'package:cv_maker_mobile/features/cv_editor/data/datasources/cv_remote_data_source.dart';
import 'package:cv_maker_mobile/features/cv_editor/data/repositories/cv_sync_repository.dart';
import 'package:cv_maker_mobile/features/cv_editor/data/repositories/local_cv_repository.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCvRemoteDataSource implements CvRemoteDataSource {
  FakeCvRemoteDataSource({
    this.shouldThrow = false,
    this.errorMessage,
    this.assignedId,
    this.remoteCvs = const [],
  });

  final bool shouldThrow;
  final String? errorMessage;
  final String? assignedId;
  final List<CvModel> remoteCvs;
  CvModel? lastUpserted;
  final List<String> deletedIds = [];

  @override
  Future<List<CvModel>> fetchUserCvs() async => remoteCvs;

  @override
  Future<CvModel> upsertCv(CvModel cv) async {
    if (shouldThrow) {
      throw CvRemoteDataSourceException(errorMessage ?? 'Sync error');
    }
    lastUpserted = cv;
    return cv.copyWith(id: assignedId, isSynced: true);
  }

  @override
  Future<void> deleteRemoteCv(String cvId) async {
    if (shouldThrow) {
      throw CvRemoteDataSourceException(errorMessage ?? 'Delete error');
    }
    deletedIds.add(cvId);
  }
}

void main() {
  late AppDatabase database;
  late LocalCvRepository localRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    localRepository = LocalCvRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  CvModel buildSampleCv({
    String id = 'cv-1',
    String? userId,
    String title = 'CV Kỹ sư phần mềm',
    DateTime? updatedAt,
    bool isSynced = false,
  }) {
    final now = updatedAt ?? DateTime.utc(2026, 10, 12, 10);
    return CvModel(
      id: id,
      userId: userId,
      title: title,
      templateId: 'harvard_ats',
      primaryColor: '#1E293B',
      fontSizeScale: 1.0,
      summary: 'Kỹ sư chuyên sâu Clean Architecture',
      personalInfo: const PersonalInfoModel(
        fullName: 'Nguyễn Tuấn Anh',
        targetRole: 'Flutter Engineer',
        email: 'tuananh@example.com',
        phone: '0901234567',
        address: 'Hà Nội',
      ),
      educations: const [],
      experiences: const [],
      skills: const [],
      projects: const [],
      isSynced: isSynced,
      createdAt: now,
      updatedAt: now,
    );
  }

  test(
    'saveAndSync persists locally and stays unsynced for guest mode (no userId)',
    () async {
      final fakeRemote = FakeCvRemoteDataSource();
      final syncRepo = CvSyncRepository(
        localRepository: localRepository,
        remoteDataSource: fakeRemote,
      );

      final cv = buildSampleCv(userId: null);
      final result = await syncRepo.saveAndSync(cv, userId: null);

      expect(result.hasError, isFalse);
      expect(result.isSynced, isFalse);
      expect(result.savedCv.title, cv.title);
      expect(fakeRemote.lastUpserted, isNull);

      final inDb = await localRepository.getById(cv.id);
      expect(inDb, isNotNull);
      expect(inDb!.isSynced, isFalse);
    },
  );

  test(
    'saveAndSync persists locally and syncs to cloud when userId is present',
    () async {
      final fakeRemote = FakeCvRemoteDataSource();
      final syncRepo = CvSyncRepository(
        localRepository: localRepository,
        remoteDataSource: fakeRemote,
      );

      final cv = buildSampleCv(userId: 'user-123');
      final result = await syncRepo.saveAndSync(cv, userId: 'user-123');

      expect(result.hasError, isFalse);
      expect(result.isSynced, isTrue);
      expect(fakeRemote.lastUpserted?.id, cv.id);

      final inDb = await localRepository.getById(cv.id);
      expect(inDb, isNotNull);
      expect(inDb!.isSynced, isTrue);
    },
  );

  test('saveAndSync preserves local copy even if cloud sync fails', () async {
    final fakeRemote = FakeCvRemoteDataSource(
      shouldThrow: true,
      errorMessage: 'Mất kết nối mạng',
    );
    final syncRepo = CvSyncRepository(
      localRepository: localRepository,
      remoteDataSource: fakeRemote,
    );

    final cv = buildSampleCv(userId: 'user-123');
    final result = await syncRepo.saveAndSync(cv, userId: 'user-123');

    expect(result.hasError, isTrue);
    expect(result.isSynced, isFalse);
    expect(result.errorMessage, 'Mất kết nối mạng');

    // Local copy must be intact
    final inDb = await localRepository.getById(cv.id);
    expect(inDb, isNotNull);
    expect(inDb!.isSynced, isFalse);
    expect(inDb.title, cv.title);
  });

  test('syncAccount claims guest drafts and stores the cloud UUID', () async {
    final guestCv = buildSampleCv(id: 'local-guest');
    await localRepository.save(guestCv);
    final cloudCv = buildSampleCv(
      id: '22222222-2222-4222-8222-222222222222',
      userId: 'user-123',
    ).copyWith(isSynced: true);
    final fakeRemote = FakeCvRemoteDataSource(
      assignedId: '11111111-1111-4111-8111-111111111111',
      remoteCvs: [cloudCv],
    );
    final syncRepo = CvSyncRepository(
      localRepository: localRepository,
      remoteDataSource: fakeRemote,
    );

    final result = await syncRepo.syncAccount('user-123');

    expect(result.isSuccess, isTrue);
    expect(result.uploadedCount, 1);
    expect(result.downloadedCount, 1);
    expect(await localRepository.getById('local-guest'), isNull);
    final claimed = await localRepository.getById(
      '11111111-1111-4111-8111-111111111111',
    );
    expect(claimed?.userId, 'user-123');
    expect(claimed?.isSynced, isTrue);
    expect(await localRepository.getById(cloudCv.id), isNotNull);
  });

  test('syncAccount downloads cloud CV when cloud version is newer', () async {
    const cvId = '33333333-3333-4333-8333-333333333333';
    final localTime = DateTime.utc(2026, 10, 20, 8);
    final cloudTime = DateTime.utc(2026, 10, 20, 9);
    await localRepository.save(
      buildSampleCv(
        id: cvId,
        userId: 'user-123',
        title: 'Bản local cũ',
        updatedAt: localTime,
      ),
      now: localTime,
    );
    final fakeRemote = FakeCvRemoteDataSource(
      remoteCvs: [
        buildSampleCv(
          id: cvId,
          userId: 'user-123',
          title: 'Bản cloud mới',
          updatedAt: cloudTime,
          isSynced: true,
        ),
      ],
    );
    final syncRepo = CvSyncRepository(
      localRepository: localRepository,
      remoteDataSource: fakeRemote,
    );

    final result = await syncRepo.syncAccount('user-123');

    expect(result.uploadedCount, 0);
    expect(result.downloadedCount, 1);
    expect(result.conflictCount, 1);
    expect(fakeRemote.lastUpserted, isNull);
    expect((await localRepository.getById(cvId))?.title, 'Bản cloud mới');
  });

  test('syncAccount uploads local CV when local version is newer', () async {
    const cvId = '44444444-4444-4444-8444-444444444444';
    final cloudTime = DateTime.utc(2026, 10, 20, 8);
    final localTime = DateTime.utc(2026, 10, 20, 9);
    await localRepository.save(
      buildSampleCv(
        id: cvId,
        userId: 'user-123',
        title: 'Bản local mới',
        updatedAt: localTime,
      ),
      now: localTime,
    );
    final fakeRemote = FakeCvRemoteDataSource(
      remoteCvs: [
        buildSampleCv(
          id: cvId,
          userId: 'user-123',
          title: 'Bản cloud cũ',
          updatedAt: cloudTime,
          isSynced: true,
        ),
      ],
    );
    final syncRepo = CvSyncRepository(
      localRepository: localRepository,
      remoteDataSource: fakeRemote,
    );

    final result = await syncRepo.syncAccount('user-123');

    expect(result.uploadedCount, 1);
    expect(result.downloadedCount, 0);
    expect(result.conflictCount, 1);
    expect(fakeRemote.lastUpserted?.title, 'Bản local mới');
  });

  test('syncAccount flushes the offline cloud deletion queue', () async {
    const cvId = '55555555-5555-4555-8555-555555555555';
    final cloudTime = DateTime.utc(2026, 10, 20, 8);
    final deletionTime = DateTime.utc(2026, 10, 20, 9);
    final existing = buildSampleCv(
      id: cvId,
      userId: 'user-123',
      updatedAt: cloudTime,
      isSynced: true,
    );
    await localRepository.save(existing, markAsLocalChange: false);
    await localRepository.deleteById(cvId, now: deletionTime);
    final fakeRemote = FakeCvRemoteDataSource(remoteCvs: [existing]);
    final syncRepo = CvSyncRepository(
      localRepository: localRepository,
      remoteDataSource: fakeRemote,
    );

    final result = await syncRepo.syncAccount('user-123');

    expect(result.deletedCount, 1);
    expect(fakeRemote.deletedIds, [cvId]);
    expect(await localRepository.getPendingDeletions('user-123'), isEmpty);
    expect(await localRepository.getById(cvId), isNull);
  });

  test('newer cloud CV wins over an older offline deletion', () async {
    const cvId = '66666666-6666-4666-8666-666666666666';
    final localTime = DateTime.utc(2026, 10, 20, 7);
    final deletionTime = DateTime.utc(2026, 10, 20, 8);
    final cloudTime = DateTime.utc(2026, 10, 20, 9);
    final localCv = buildSampleCv(
      id: cvId,
      userId: 'user-123',
      title: 'Bản đã xoá trên máy',
      updatedAt: localTime,
      isSynced: true,
    );
    await localRepository.save(localCv, markAsLocalChange: false);
    await localRepository.deleteById(cvId, now: deletionTime);
    final cloudCv = buildSampleCv(
      id: cvId,
      userId: 'user-123',
      title: 'Bản cloud vừa sửa',
      updatedAt: cloudTime,
      isSynced: true,
    );
    final fakeRemote = FakeCvRemoteDataSource(remoteCvs: [cloudCv]);
    final syncRepo = CvSyncRepository(
      localRepository: localRepository,
      remoteDataSource: fakeRemote,
    );

    final result = await syncRepo.syncAccount('user-123');

    expect(result.deletedCount, 0);
    expect(result.downloadedCount, 1);
    expect(result.conflictCount, 1);
    expect(fakeRemote.deletedIds, isEmpty);
    expect((await localRepository.getById(cvId))?.title, 'Bản cloud vừa sửa');
    expect(await localRepository.getPendingDeletions('user-123'), isEmpty);
  });

  test('inspectSyncPreview returns pending upload, download, and conflict counts without mutating database', () async {
    const cvLocalOnly = '11111111-1111-4111-8111-111111111111';
    const cvRemoteOnly = '22222222-2222-4222-8222-222222222222';
    const cvConflict = '33333333-3333-4333-8333-333333333333';

    // Local-only CV (needs upload)
    await localRepository.save(
      buildSampleCv(id: cvLocalOnly, userId: 'user-123', updatedAt: DateTime.utc(2026, 10, 20, 10), isSynced: false),
      markAsLocalChange: true,
    );

    // Conflict CV: local has edit, remote also has edit
    await localRepository.save(
      buildSampleCv(id: cvConflict, userId: 'user-123', updatedAt: DateTime.utc(2026, 10, 20, 12), isSynced: false),
      markAsLocalChange: true,
    );

    final remoteCvs = [
      buildSampleCv(id: cvRemoteOnly, userId: 'user-123', updatedAt: DateTime.utc(2026, 10, 20, 11), isSynced: true),
      buildSampleCv(id: cvConflict, userId: 'user-123', updatedAt: DateTime.utc(2026, 10, 20, 14), isSynced: true),
    ];

    final fakeRemote = FakeCvRemoteDataSource(remoteCvs: remoteCvs);
    final syncRepo = CvSyncRepository(
      localRepository: localRepository,
      remoteDataSource: fakeRemote,
    );

    final preview = await syncRepo.inspectSyncPreview(
      userId: 'user-123',
      userEmail: 'tuananh@example.com',
      backendLabel: 'Supabase Primary',
    );

    expect(preview.hasError, isFalse);
    expect(preview.targetBackend, 'Supabase Primary');
    expect(preview.userEmail, 'tuananh@example.com');
    expect(preview.localCvCount, 2);
    expect(preview.remoteCvCount, 2);
    expect(preview.hasChanges, isTrue);
    expect(preview.pendingDownloadCount, greaterThanOrEqualTo(1));
    expect(preview.conflictCount, greaterThanOrEqualTo(1));

    // Guarantee read-only: local DB was not modified!
    final localAfter = await localRepository.getAll();
    expect(localAfter.length, 2);
    expect(await localRepository.getById(cvRemoteOnly), isNull);
  });

}
