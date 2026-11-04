import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/docx_export_service_impl.dart';
import '../../domain/repositories/document_export_repository.dart';

final docxExportServiceProvider = Provider<DocumentExportRepository>((ref) {
  return const DocxExportServiceImpl();
});
