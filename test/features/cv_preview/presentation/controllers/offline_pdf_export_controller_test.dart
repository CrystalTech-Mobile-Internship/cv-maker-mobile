import 'dart:typed_data';

import 'package:cv_maker_mobile/features/cv_editor/domain/models/cv_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/repositories/cv_repository.dart';
import 'package:cv_maker_mobile/features/cv_preview/domain/services/pdf_export_service.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/controllers/offline_pdf_export_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps CV and PDF locally when native sharing fails', () async {
    final repository = _FakeCvRepository();
    final pdfService = _FakePdfService(shareFails: true);
    final controller = OfflinePdfExportController(
      cvRepository: repository,
      pdfService: pdfService,
    );

    final result = await controller.export(
      cv: CvModel.empty(id: 'offline-cv'),
      pdfBytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'offline.pdf',
      persistCv: true,
    );

    expect(repository.savedIds, ['offline-cv']);
    expect(pdfService.savedFileNames, ['offline.pdf']);
    expect(result.localPath, '/device/offline.pdf');
    expect(result.sharingOpened, isFalse);
  });

  test('can export a preview sample without persisting a fake CV', () async {
    final repository = _FakeCvRepository();
    final pdfService = _FakePdfService();
    final controller = OfflinePdfExportController(
      cvRepository: repository,
      pdfService: pdfService,
    );

    final result = await controller.export(
      cv: CvModel.empty(id: 'preview-sample'),
      pdfBytes: Uint8List.fromList([1]),
      fileName: 'sample.pdf',
      persistCv: false,
    );

    expect(repository.savedIds, isEmpty);
    expect(result.sharingOpened, isTrue);
  });
}

final class _FakePdfService implements PdfExportService {
  _FakePdfService({this.shareFails = false});

  final bool shareFails;
  final List<String> savedFileNames = [];

  @override
  Future<Uint8List> generateCvPdf({
    required CvModel cv,
    required String language,
    String templateId = 'harvard_ats',
  }) async => Uint8List.fromList([1]);

  @override
  Future<String> savePdfLocally({
    required Uint8List bytes,
    required String fileName,
  }) async {
    savedFileNames.add(fileName);
    return '/device/$fileName';
  }

  @override
  Future<void> shareOrSavePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (shareFails) throw StateError('No sharing target');
  }
}

final class _FakeCvRepository implements CvRepository {
  final List<String> savedIds = [];

  @override
  Future<CvModel> save(
    CvModel cv, {
    bool markAsLocalChange = true,
    DateTime? now,
  }) async {
    savedIds.add(cv.id);
    return cv.copyWith(isSynced: false);
  }

  @override
  Stream<List<CvModel>> watchAll() => const Stream.empty();

  @override
  Future<List<CvModel>> getAll() async => [];

  @override
  Future<CvModel?> getById(String id) async => null;

  @override
  Future<List<CvModel>> getPendingSync(String userId) async => [];

  @override
  Future<List<CvDeletionRequest>> getPendingDeletions(String userId) async =>
      [];

  @override
  Future<CvModel> duplicate(
    String sourceId, {
    required String newId,
    DateTime? now,
  }) async => throw UnimplementedError();

  @override
  Future<bool> markSynced(String id) async => true;

  @override
  Future<bool> deleteById(String id, {DateTime? now}) async => true;

  @override
  Future<bool> confirmDeletionSynced(String id) async => true;
}
