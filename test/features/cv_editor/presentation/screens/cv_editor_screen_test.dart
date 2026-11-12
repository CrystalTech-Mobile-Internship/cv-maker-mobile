import 'package:cv_maker_mobile/features/ai_tools/domain/models/summary_polish_request.dart';
import 'package:cv_maker_mobile/features/ai_tools/domain/models/summary_polish_result.dart';
import 'package:cv_maker_mobile/features/ai_tools/domain/repositories/ai_writing_repository.dart';
import 'package:cv_maker_mobile/features/ai_tools/presentation/controllers/summary_polish_controller.dart';
import 'package:cv_maker_mobile/features/auth/domain/models/auth_user.dart';
import 'package:cv_maker_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:cv_maker_mobile/features/cv_editor/data/repositories/cv_repository_provider.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/repositories/cv_repository.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/screens/cv_editor_screen.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/screens/cv_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';

class MockCvRepo implements CvRepository {
  MockCvRepo({this.shouldFailSave});

  final bool Function(CvModel cv)? shouldFailSave;
  final List<CvModel> list = [];

  @override
  Future<bool> confirmDeletionSynced(String id) async => true;

  @override
  Future<bool> deleteById(String id, {DateTime? now}) async {
    list.removeWhere((c) => c.id == id);
    return true;
  }

  @override
  Future<CvModel> duplicate(
    String sourceId, {
    required String newId,
    DateTime? now,
  }) async {
    final cv = list.firstWhere((c) => c.id == sourceId);
    final dup = cv.copyWith(id: newId);
    list.add(dup);
    return dup;
  }

  @override
  Future<List<CvModel>> getAll() async => list;

  @override
  Future<CvModel?> getById(String id) async =>
      list.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<CvDeletionRequest>> getPendingDeletions(String userId) async =>
      [];

  @override
  Future<List<CvModel>> getPendingSync(String userId) async => [];

  @override
  Future<bool> markSynced(String id) async => true;

  @override
  Future<CvModel> replaceWithSynced(String localId, CvModel syncedCv) async {
    list.removeWhere((cv) => cv.id == localId);
    list.add(syncedCv);
    return syncedCv;
  }

  @override
  Future<CvModel> save(
    CvModel cv, {
    bool markAsLocalChange = true,
    DateTime? now,
  }) async {
    if (shouldFailSave?.call(cv) == true) {
      throw StateError('Simulated local save failure');
    }
    list.removeWhere((c) => c.id == cv.id);
    list.add(cv);
    return cv;
  }

  @override
  Stream<List<CvModel>> watchAll() async* {
    yield list;
  }
}

class _SequencedAiRepository implements AiWritingRepository {
  int calls = 0;

  @override
  Future<SummaryPolishResult> polishSummary(
    SummaryPolishRequest request,
  ) async {
    calls++;
    return SummaryPolishResult(
      suggestedSummary: calls == 1
          ? 'Gợi ý AI lần đầu vẫn chỉ là bản xem trước cho người dùng.'
          : 'Gợi ý AI lần hai được người dùng xác nhận và lưu trên thiết bị.',
      provider: 'Test AI',
    );
  }
}

const _signedInUser = AuthUser(
  id: 'user-ai-test',
  email: 'owner@example.com',
  displayName: 'Owner',
  provider: 'email',
  isEmailConfirmed: true,
);

void main() {
  testWidgets('desktop editor shows a restrained live A4 preview pane', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(MockCvRepo())],
        child: const MaterialApp(home: CvEditorScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Xem trước A4 trực tiếp'), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byType(PdfPreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('contact fields stack at Samsung A11 logical width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(MockCvRepo())],
        child: const MaterialApp(home: CvEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final emailField = find.byKey(const Key('email-field'));
    final phoneField = find.byKey(const Key('phone-field'));
    await tester.ensureVisible(emailField);
    await tester.pumpAndSettle();

    expect(tester.getSize(emailField).width, greaterThan(300));
    expect(tester.getSize(phoneField).width, greaterThan(300));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'project and certification empty states stay vertically centered',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [cvRepositoryProvider.overrideWithValue(MockCvRepo())],
          child: const MaterialApp(home: CvEditorScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('editor-tab-icon-4')));
      await tester.pumpAndSettle();
      final projects = find.byKey(const Key('projects-empty-state'));
      expect(projects, findsOneWidget);
      expect(tester.getCenter(projects).dy, inInclusiveRange(350, 620));

      await tester.tap(find.byKey(const ValueKey('editor-tab-icon-5')));
      await tester.pumpAndSettle();
      final certifications = find.byKey(
        const Key('certifications-empty-state'),
      );
      expect(certifications, findsOneWidget);
      expect(tester.getCenter(certifications).dy, inInclusiveRange(350, 620));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('AI retry saves only the suggestion the user applies', (
    tester,
  ) async {
    final repo = MockCvRepo();
    final aiRepository = _SequencedAiRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cvRepositoryProvider.overrideWithValue(repo),
          currentAuthUserProvider.overrideWithValue(_signedInUser),
          aiWritingRepositoryProvider.overrideWithValue(aiRepository),
        ],
        child: const MaterialApp(home: CvEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('target-role-field')),
      'Flutter Developer',
    );
    await tester.enterText(
      find.byKey(const Key('summary-field')),
      'Lập trình viên Flutter tập trung vào ứng dụng mobile ổn định và trải nghiệm người dùng.',
    );
    final aiButton = find.byKey(const Key('polish-summary-with-ai'));
    await tester.ensureVisible(aiButton);
    await tester.tap(aiButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Gợi ý AI lần đầu'), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry-ai-summary')));
    await tester.pumpAndSettle();

    expect(aiRepository.calls, 2);
    expect(find.textContaining('Gợi ý AI lần hai'), findsOneWidget);
    await tester.tap(find.byKey(const Key('apply-ai-summary')));
    await tester.pumpAndSettle();

    expect(repo.list.single.summary, contains('lần hai'));
    expect(repo.list.single.summary, isNot(contains('lần đầu')));
  });

  testWidgets('AI save failure keeps the original summary in UI and local CV', (
    tester,
  ) async {
    const original =
        'Lập trình viên Flutter tập trung vào ứng dụng mobile ổn định và trải nghiệm người dùng.';
    final repo = MockCvRepo(
      shouldFailSave: (cv) => cv.summary.startsWith('Gợi ý AI'),
    );
    final aiRepository = _SequencedAiRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cvRepositoryProvider.overrideWithValue(repo),
          currentAuthUserProvider.overrideWithValue(_signedInUser),
          aiWritingRepositoryProvider.overrideWithValue(aiRepository),
        ],
        child: const MaterialApp(home: CvEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('target-role-field')),
      'Flutter Developer',
    );
    await tester.enterText(find.byKey(const Key('summary-field')), original);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    final aiButton = find.byKey(const Key('polish-summary-with-ai'));
    await tester.ensureVisible(aiButton);
    await tester.tap(aiButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apply-ai-summary')));
    await tester.pumpAndSettle();

    final summaryField = tester.widget<TextField>(
      find.byKey(const Key('summary-field')),
    );
    expect(summaryField.controller?.text, original);
    expect(repo.list.single.summary, original);
    expect(find.text('Chưa áp dụng'), findsOneWidget);
  });

  testWidgets('new CV keeps one stable local id across auto-saves', (
    tester,
  ) async {
    final repo = MockCvRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: CvEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'Nguyễn Văn A');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    final firstId = repo.list.single.id;

    await tester.enterText(find.byType(TextField).at(2), 'Flutter Developer');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(repo.list, hasLength(1));
    expect(repo.list.single.id, firstId);
  });

  testWidgets('CvEditorScreen renders full-width tabs and toggles language', (
    tester,
  ) async {
    final repo = MockCvRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: CvEditorScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // The tab row uses the full width: selected tab shows text, inactive tabs
    // show only their icons.
    expect(find.text('Cá nhân'), findsOneWidget);
    expect(find.text('Học vấn'), findsNothing);
    expect(find.byKey(const ValueKey('editor-tab-icon-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('editor-tab-icon-1')));
    await tester.pumpAndSettle();
    expect(find.text('Học vấn'), findsOneWidget);
    expect(find.text('Cá nhân'), findsNothing);

    // Switch to English via the compact language selector.
    final languageToggle = find.byKey(const Key('editor-language-toggle'));
    expect(find.text('VI'), findsOneWidget);
    await tester.tap(languageToggle);
    await tester.pumpAndSettle();

    // The active Education tab changes language; inactive tabs remain icons.
    expect(find.text('Personal'), findsNothing);
    expect(find.text('Education'), findsOneWidget);
    expect(find.text('Experience'), findsNothing);
    expect(find.byKey(const ValueKey('editor-tab-icon-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('editor-tab-icon-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pick-profile-photo')), findsOneWidget);

    // Verify English form fields
    expect(find.text('Full Name *'), findsOneWidget);
    expect(find.text('Target Role / Job Title *'), findsOneWidget);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((field) => field.controller?.text.isEmpty ?? true),
      isTrue,
      reason: 'Changing language must not insert or overwrite CV data.',
    );
  });

  testWidgets('education form rejects missing and invalid date input', (
    tester,
  ) async {
    final repo = MockCvRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: CvEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('editor-tab-icon-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm mục mới'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập tên trường và bằng cấp.'), findsOneWidget);
    expect(repo.list, isEmpty);

    var fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    await tester.enterText(find.byType(TextField).at(0), 'Đại học Đà Nẵng');
    await tester.enterText(find.byType(TextField).at(1), 'Cử nhân');
    await tester.enterText(find.byType(TextField).at(3), '2025');
    await tester.enterText(find.byType(TextField).at(4), '2024');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(
      find.text('Năm tốt nghiệp không thể trước năm bắt đầu.'),
      findsOneWidget,
    );
    expect(repo.list, isEmpty);

    fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields, hasLength(6));
    await tester.enterText(find.byType(TextField).at(4), '2025');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump();

    expect(repo.list.single.educations.single.institution, 'Đại học Đà Nẵng');
    expect(repo.list.single.educations.single.degree, 'Cử nhân');
    expect(repo.list.single.educations.single.startDate.year, 2025);
    expect(repo.list.single.educations.single.endDate?.year, 2025);
  });

  testWidgets('experience form rejects out-of-range months', (tester) async {
    final repo = MockCvRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: CvEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('editor-tab-icon-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm mục mới'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Kỹ sư Flutter');
    await tester.enterText(find.byType(TextField).at(1), 'Công ty công nghệ');
    await tester.enterText(find.byType(TextField).at(3), '13');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nhập tháng từ 1 đến 12 và năm từ 1900 đến 2100.'),
      findsOneWidget,
    );
    expect(repo.list, isEmpty);

    await tester.enterText(find.byType(TextField).at(3), '12');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump();

    expect(repo.list.single.experiences.single.jobTitle, 'Kỹ sư Flutter');
    expect(repo.list.single.experiences.single.startDate.month, 12);
    expect(repo.list.single.experiences.single.isCurrent, isTrue);
  });

  testWidgets('CvPreviewScreen renders the generated A4 PDF and controls', (
    tester,
  ) async {
    final repo = MockCvRepo();
    final testCv = CvModel(
      id: 'preview-test-1',
      title: 'Senior Flutter Architect',
      templateId: 'harvard_ats',
      language: 'vi',
      primaryColor: '#1E293B',
      fontSizeScale: 1.0,
      summary: 'Kỹ sư kiến trúc hệ thống 5 năm kinh nghiệm.',
      personalInfo: const PersonalInfoModel(
        fullName: 'Trần Văn Hoàng',
        targetRole: 'Mobile Tech Lead',
        email: 'hoang.tran@enterprise.com',
        phone: '0988 777 666',
        address: 'Đà Nẵng, Việt Nam',
      ),
      educations: [
        EducationModel(
          id: 'edu-h',
          institution: 'Đại học Bách Khoa Đà Nẵng',
          degree: 'Thạc sĩ Khoa học Máy tính',
          fieldOfStudy: 'Khoa học Máy tính',
          startDate: DateTime(2018, 9, 1).toUtc(),
          endDate: DateTime(2022, 6, 30).toUtc(),
          gpa: '3.9 / 4.0',
        ),
      ],
      experiences: const [],
      skills: const [],
      projects: const [],
      isSynced: true,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: CvPreviewScreen(cv: testCv)),
      ),
    );

    await tester.pump();

    // CV content is rasterized from the same PDF bytes used for export, so it
    // is intentionally not duplicated as Flutter Text widgets anymore.
    expect(find.byType(PdfPreview), findsOneWidget);
    expect(find.text('Xem trước'), findsOneWidget);
    expect(find.byKey(const Key('preview-more-menu')), findsOneWidget);
    await tester.tap(find.byKey(const Key('preview-more-menu')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Cỡ chữ, vừa trang'), findsOneWidget);
    expect(find.text('Ẩn nội dung mẫu'), findsOneWidget);
    expect(find.text('Tải tệp (PDF / Word)'), findsOneWidget);
  });
}
