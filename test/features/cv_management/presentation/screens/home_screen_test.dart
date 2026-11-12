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
    expect(find.byKey(const Key('home-create-cv')), findsOneWidget);

    // Tap the create action in the app bar.
    await tester.tap(find.byKey(const Key('home-create-cv')));
    await tester.pumpAndSettle();

    // Verify create dialog appears
    expect(find.text('Tạo hồ sơ CV mới'), findsOneWidget);
    expect(find.text('Harvard ATS'), findsOneWidget);
    expect(find.text('Minimalist Clean'), findsOneWidget);
    // Pro designs are not offered to Free accounts.
    expect(find.text('Creative Tech'), findsNothing);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('Điền hồ sơ mẫu sinh viên CNTT'), findsNothing);
    expect(find.text('VD: CV Flutter Software Engineer'), findsOneWidget);

    final submitButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Tạo ngay'),
    );
    expect(submitButton.onPressed, isNull);
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
    await tester.scrollUntilVisible(
      find.text('Đăng nhập để đồng bộ'),
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('my-cvs')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Đăng nhập để đồng bộ'), findsOneWidget);
  });

  testWidgets('CV library supports search, filtering, sorting and checklist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepo = FakeCvRepository();
    final now = DateTime.now().toUtc();
    await fakeRepo.save(
      CvModel(
        id: 'flutter-cv',
        title: 'Flutter Developer',
        templateId: 'harvard_ats',
        primaryColor: '#1E293B',
        fontSizeScale: 1,
        summary: 'Flutter summary',
        personalInfo: const PersonalInfoModel(
          fullName: 'Nguyễn An',
          targetRole: 'Mobile Developer',
          email: 'an@example.com',
          phone: '0901000000',
        ),
        isSynced: true,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    );
    await fakeRepo.save(
      CvModel(
        id: 'backend-cv',
        title: 'Backend Engineer',
        templateId: 'modern_blue',
        primaryColor: '#1E293B',
        fontSizeScale: 1,
        summary: '',
        personalInfo: const PersonalInfoModel(targetRole: 'Java Developer'),
        isSynced: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    // Search and filters appear once the library has more than three CVs.
    for (final title in ['Archive One', 'Archive Two']) {
      await fakeRepo.save(
        CvModel.empty(
          id: title,
          now: now.subtract(const Duration(days: 30)),
        ).copyWith(title: title),
        markAsLocalChange: false,
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('cv-library-search')),
      'Flutter',
    );
    await tester.pumpAndSettle();
    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(find.text('Backend Engineer'), findsNothing);

    await tester.enterText(find.byKey(const Key('cv-library-search')), '');
    await tester.pumpAndSettle();
    Future<void> pickOption(String label) async {
      await tester.tap(find.byKey(const Key('cv-library-options')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    }

    await pickOption('Đã sao lưu');
    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(find.text('Backend Engineer'), findsNothing);

    await pickOption('Tất cả');
    await pickOption('Tên A–Z');
    expect(
      tester.getTopLeft(find.text('Backend Engineer')).dy,
      lessThan(tester.getTopLeft(find.text('Flutter Developer')).dy),
    );

    final checklist = find.byKey(const ValueKey('cv-checklist-flutter-cv'));
    await tester.scrollUntilVisible(
      checklist,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(checklist);
    await tester.pumpAndSettle();
    expect(find.text('Checklist hoàn thiện CV'), findsOneWidget);
    expect(find.text('Còn thiếu'), findsNWidgets(4));
    expect(find.byKey(const Key('continue-cv-editing')), findsOneWidget);
    expect(tester.takeException(), isNull);
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

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-ai-interview')),
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('my-cvs')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Tải CV PDF/Word'), findsOneWidget);

    await tester.tap(find.text('Mẫu CV'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn mẫu CV'), findsOneWidget);
    expect(find.text('Premium & AI sắp ra mắt'), findsNothing);
    expect(find.byKey(const Key('template-filter-row')), findsOneWidget);
    expect(find.text('Harvard ATS'), findsOneWidget);
    expect(find.text('Mẫu CV miễn phí'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('template-filter-premium')));
    await tester.pumpAndSettle();
    expect(find.text('Gói Pro'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account is an in-place tab and keeps bottom navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(FakeCvRepository())],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byTooltip('Đăng nhập'), findsNothing);
    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();

    expect(
      find.text('Đăng nhập để sao lưu CV và dùng trên nhiều thiết bị'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('premium availability label fits on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(FakeCvRepository())],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mẫu CV'));
    await tester.pumpAndSettle();
    final premiumFilter = find.byKey(const ValueKey('template-filter-premium'));
    await tester.scrollUntilVisible(
      premiumFilter,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final filterRect = tester.getRect(premiumFilter);
    expect(filterRect.left, greaterThanOrEqualTo(0));
    expect(filterRect.right, lessThanOrEqualTo(320));
    final filterCenters = ['all', 'photo', 'noPhoto', 'premium'].map(
      (name) => tester.getCenter(find.byKey(ValueKey('template-filter-$name'))),
    );
    expect(filterCenters.map((center) => center.dy).toSet(), hasLength(1));
    await tester.tap(premiumFilter);
    await tester.pumpAndSettle();

    final label = find.text('Gói Pro').first;
    await tester.scrollUntilVisible(
      label,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final button = find
        .ancestor(of: label, matching: find.byType(OutlinedButton))
        .first;
    final labelRect = tester.getRect(label);
    final buttonRect = tester.getRect(button);
    expect(labelRect.left, greaterThanOrEqualTo(buttonRect.left));
    expect(labelRect.right, lessThanOrEqualTo(buttonRect.right));
    expect(tester.takeException(), isNull);
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
