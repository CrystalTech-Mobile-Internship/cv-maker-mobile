import 'package:cv_maker_mobile/features/cv_editor/data/repositories/cv_repository_provider.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/cv_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/personal_info_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/repositories/cv_repository.dart';
import 'package:cv_maker_mobile/features/cv_management/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCvRepository implements CvRepository {
  final List<CvModel> _cvs = [];

  @override
  Stream<List<CvModel>> watchAll() async* {
    yield List.unmodifiable(_cvs);
  }

  @override
  Future<List<CvModel>> getAll() async => List.unmodifiable(_cvs);

  @override
  Future<CvModel?> getById(String id) async =>
      _cvs.where((cv) => cv.id == id).firstOrNull;

  @override
  Future<List<CvModel>> getPendingSync(String userId) async => [];

  @override
  Future<List<CvDeletionRequest>> getPendingDeletions(String userId) async =>
      [];

  @override
  Future<CvModel> save(
    CvModel cv, {
    bool markAsLocalChange = true,
    DateTime? now,
  }) async {
    _cvs.removeWhere((item) => item.id == cv.id);
    _cvs.insert(0, cv);
    return cv;
  }

  @override
  Future<CvModel> duplicate(
    String sourceId, {
    required String newId,
    DateTime? now,
  }) async {
    final source = await getById(sourceId);
    if (source == null) throw CvNotFoundException(sourceId);
    final dup = source.copyWith(id: newId, title: '${source.title} (Bản sao)');
    _cvs.insert(0, dup);
    return dup;
  }

  @override
  Future<bool> markSynced(String id) async => true;

  @override
  Future<CvModel> replaceWithSynced(String localId, CvModel syncedCv) async {
    _cvs.removeWhere((item) => item.id == localId);
    _cvs.insert(0, syncedCv);
    return syncedCv;
  }

  @override
  Future<bool> deleteById(String id, {DateTime? now}) async {
    _cvs.removeWhere((item) => item.id == id);
    return true;
  }

  @override
  Future<bool> confirmDeletionSynced(String id) async => true;
}

void main() {
  testWidgets('HomeScreen renders empty state and open create dialog', (
    tester,
  ) async {
    final fakeRepo = FakeCvRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Initial load
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify empty state is rendered
    expect(find.text('Chưa có hồ sơ CV nào'), findsOneWidget);
    expect(find.text('Tạo CV mới'), findsOneWidget);

    // Tap '+ Tạo CV mới' floating action button
    await tester.tap(find.text('Tạo CV mới'));
    await tester.pumpAndSettle();

    // Verify create dialog appears
    expect(find.text('Tạo hồ sơ CV mới'), findsOneWidget);
    expect(find.text('Harvard ATS'), findsOneWidget);
    expect(find.text('Minimalist Clean'), findsOneWidget);
    expect(find.text('Creative Tech'), findsOneWidget);
    expect(find.text('🇻🇳 Tiếng Việt'), findsOneWidget);
    expect(find.text('Điền hồ sơ mẫu sinh viên CNTT'), findsNothing);
    expect(find.text('VD: CV Flutter Software Engineer'), findsOneWidget);

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Tạo ngay'),
    );
    expect(createButton.onPressed, isNull);
  });

  testWidgets('HomeScreen displays CV cards when repository has data', (
    tester,
  ) async {
    final fakeRepo = FakeCvRepository();
    final now = DateTime.now().toUtc();
    await fakeRepo.save(
      CvModel(
        id: 'test-cv-1',
        title: 'CV Kỹ sư Phần mềm',
        templateId: 'harvard_ats',
        primaryColor: '#1E293B',
        fontSizeScale: 1.0,
        summary: 'Tóm tắt mẫu',
        personalInfo: const PersonalInfoModel(
          fullName: 'Nguyễn Tuấn Anh',
          targetRole: 'Senior Flutter Developer',
          email: 'tuananh@test.com',
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
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('CV Kỹ sư Phần mềm'), findsOneWidget);
    expect(find.text('Senior Flutter Developer'), findsOneWidget);
    expect(find.text('Trên máy'), findsOneWidget);
    expect(find.text('Đăng nhập để đồng bộ'), findsOneWidget);
  });

  testWidgets('Mẫu CV is a real catalog tab with free and premium states', (
    tester,
  ) async {
    final fakeRepo = FakeCvRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mẫu CV'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn phong cách của bạn'), findsOneWidget);
    expect(find.text('8 mẫu miễn phí • Xem trước trực quan'), findsOneWidget);
    expect(find.text('Premium & AI sắp ra mắt'), findsOneWidget);
    expect(find.text('Harvard ATS'), findsOneWidget);
    expect(find.text('Mẫu CV miễn phí'), findsNothing);
  });

  testWidgets('catalog selection is prioritized in the create dialog', (
    tester,
  ) async {
    final fakeRepo = FakeCvRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mẫu CV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Có ảnh'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dùng mẫu').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dùng mẫu').first);
    await tester.pumpAndSettle();

    expect(find.text('Tạo hồ sơ CV mới'), findsOneWidget);
    expect(find.text('Minimalist Clean'), findsNWidgets(2));
    expect(find.text('ĐÃ CHỌN'), findsOneWidget);
  });
}
