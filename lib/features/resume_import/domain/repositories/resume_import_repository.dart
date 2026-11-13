import 'dart:typed_data';

import '../models/resume_import_draft.dart';

/// Plain text extracted on-device from an uploaded DOCX/PDF resume.
final class ResumeTextSource {
  const ResumeTextSource({required this.fileName, required this.text});

  final String fileName;
  final String text;
}

abstract interface class ResumeImportRepository {
  Future<ResumeImportDraft?> pickAndParse();

  /// Lets the user pick a DOCX/PDF and extracts its text without parsing.
  Future<ResumeTextSource?> pickAndExtractText();

  /// Heuristic, fully offline parser for previously extracted text.
  ResumeImportDraft parseText(ResumeTextSource source);

  Future<ResumeImportDraft> parseBytes({
    required String fileName,
    required Uint8List bytes,
  });
}

final class ResumeImportException implements Exception {
  const ResumeImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
