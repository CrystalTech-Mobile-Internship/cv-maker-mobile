import 'package:cv_maker_mobile/core/database/app_database.dart';
import 'package:cv_maker_mobile/features/cv_editor/data/datasources/cv_remote_data_source.dart';
import 'package:cv_maker_mobile/features/cv_editor/data/repositories/cv_sync_repository.dart';
import 'package:cv_maker_mobile/features/cv_editor/data/repositories/local_cv_repository.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCvRemoteDataSource implements CvRemoteDataSource {
  FakeCvRemoteDataSource({this.shouldThrow = false, this.errorMessage});

  final bool shouldThrow;
  final String? errorMessage;
  CvModel? lastUpserted;

  @override
  Future<List<CvModel>> fetchUserCvs() async => const [];

  @override
  Future<CvModel> upsertCv(CvModel cv) async {
    if (shouldThrow) {
      throw CvRemoteDataSourceException(errorMessage ?? 'Sync error');
    }
    lastUpserted = cv;
    return cv.copyWith(isSynced: true);
  }

  @override
  Future<void> deleteRemoteCv(String cvId) async {}
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

  CvModel buildSampleCv({String id = 'cv-1', String? userId}) {
    final now = DateTime.utc(2026, 10, 12, 10);
    return CvModel(
      id: id,
      userId: userId,
      title: 'CV Kỹ sư phần mềm',
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
      isSynced: false,
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
}
