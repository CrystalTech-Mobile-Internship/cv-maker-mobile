import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/pdf_export_service_impl.dart';
import '../../domain/services/pdf_export_service.dart';

/// Riverpod provider for PDF Export Service
final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportServiceImpl();
});
