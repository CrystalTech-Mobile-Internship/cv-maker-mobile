import 'package:cv_maker_mobile/features/cv_editor/data/repositories/cv_repository_provider.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/repositories/cv_repository.dart';
import 'package:cv_maker_mobile/features/cv_editor/presentation/screens/cv_editor_screen.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/screens/cv_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockCvRepo implements CvRepository {
  final List<CvModel> list = [];

  @override
  Future<bool> confirmDeletionSynced(String id) async => true;

  @override
  Future<bool> deleteById(String id, {DateTime? now}) async {
    list.removeWhere((c) => c.id == id);
    return true;
  }

  @override
  Future<CvModel> duplicate(String sourceId,
      {required String newId, DateTime? now}) async {
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
  Future<List<CvDeletionRequest>> getPendingDeletions(String userId) async => [];

  @override
  Future<List<CvModel>> getPendingSync(String userId) async => [];

  @override
  Future<bool> markSynced(String id) async => true;

  @override
  Future<CvModel> save(CvModel cv,
      {bool markAsLocalChange = true, DateTime? now}) async {
    list.removeWhere((c) => c.id == cv.id);
    list.add(cv);
    return cv;
  }

  @override
  Stream<List<CvModel>> watchAll() async* {
    yield list;
  }
}

void main() {
  testWidgets('CvEditorScreen renders full-width tabs and toggles language',
      (tester) async {
    final repo = MockCvRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cvRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: CvEditorScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Vietnamese tabs are rendered by default
    expect(find.text('Cá nhân'), findsOneWidget);
    expect(find.text('Học vấn'), findsOneWidget);
    expect(find.text('Kinh nghiệm'), findsOneWidget);
    expect(find.text('Kỹ năng'), findsOneWidget);

    // Switch to English via SegmentedButton '🇬🇧 EN'
    final enButton = find.text('🇬🇧 EN');
    expect(enButton, findsOneWidget);
    await tester.tap(enButton);
    await tester.pumpAndSettle();

    // Verify English tabs are now rendered
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Education'), findsOneWidget);
    expect(find.text('Experience'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);

    // Verify English form fields
    expect(find.text('Full Name *'), findsOneWidget);
    expect(find.text('Target Role / Job Title *'), findsOneWidget);
  });

  testWidgets('CvPreviewScreen renders dynamic CV Model values correctly',
      (tester) async {
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
      MaterialApp(
        home: CvPreviewScreen(cv: testCv),
      ),
    );

    await tester.pumpAndSettle();

    // Verify dynamic name and role are displayed
    expect(find.text('TRẦN VĂN HOÀNG'), findsOneWidget);
    expect(find.text('MOBILE TECH LEAD'), findsOneWidget);
    expect(find.textContaining('hoang.tran@enterprise.com'), findsOneWidget);
    expect(find.text('Kỹ sư kiến trúc hệ thống 5 năm kinh nghiệm.'), findsOneWidget);
    expect(find.text('ĐẠI HỌC BÁCH KHOA ĐÀ NẴNG'), findsOneWidget);
  });
}
