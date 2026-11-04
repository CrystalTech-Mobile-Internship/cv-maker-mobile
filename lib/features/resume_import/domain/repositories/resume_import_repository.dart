import 'dart:typed_data';

import '../models/resume_import_draft.dart';

abstract interface class ResumeImportRepository {
  Future<ResumeImportDraft?> pickAndParse();

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
