import 'dart:typed_data';

import '../../../cv_editor/domain/models/cv_model.dart';

/// Clean Architecture Domain Contract for PDF document generation & export.
abstract class PdfExportService {
  /// Generates vector A4 PDF bytes based on CV data, language, and template.
  Future<Uint8List> generateCvPdf({
    required CvModel cv,
    required String language,
    String templateId = 'harvard_ats',
  });

  /// Saves the generated PDF bytes to the device's local file storage.
  /// Returns the absolute path where the file was saved.
  Future<String> savePdfLocally({
    required Uint8List bytes,
    required String fileName,
  });

  /// Invokes the native platform share/save sheet so the user can save
  /// to phone Files (My Files/Downloads), Google Drive, or send via apps.
  Future<void> shareOrSavePdf({
    required Uint8List bytes,
    required String fileName,
  });
}
