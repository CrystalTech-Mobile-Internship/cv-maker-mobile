import 'dart:typed_data';

import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/repositories/cv_repository.dart';
import '../../domain/services/pdf_export_service.dart';

final class OfflinePdfExportController {
  const OfflinePdfExportController({
    required CvRepository cvRepository,
    required PdfExportService pdfService,
  }) : _cvRepository = cvRepository,
       _pdfService = pdfService;

  final CvRepository _cvRepository;
  final PdfExportService _pdfService;

  Future<OfflinePdfExportResult> export({
    required CvModel cv,
    required Uint8List pdfBytes,
    required String fileName,
    required bool persistCv,
  }) async {
    final savedCv = persistCv ? await _cvRepository.save(cv) : cv;
    final localPath = await _pdfService.savePdfLocally(
      bytes: pdfBytes,
      fileName: fileName,
    );

    try {
      await _pdfService.shareOrSavePdf(bytes: pdfBytes, fileName: fileName);
      return OfflinePdfExportResult(
        cv: savedCv,
        localPath: localPath,
        sharingOpened: true,
      );
    } catch (_) {
      return OfflinePdfExportResult(
        cv: savedCv,
        localPath: localPath,
        sharingOpened: false,
      );
    }
  }
}

final class OfflinePdfExportResult {
  const OfflinePdfExportResult({
    required this.cv,
    required this.localPath,
    required this.sharingOpened,
  });

  final CvModel cv;
  final String localPath;
  final bool sharingOpened;
}
