import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_preview/data/services/pdf_export_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PdfExportServiceImpl generates valid A4 PDF bytes starting with %PDF', () async {
    final service = PdfExportServiceImpl();
    final cv = CvModel.empty(id: 'test_pdf_cv');

    final bytes = await service.generateCvPdf(
      cv: cv,
      language: 'vi',
      templateId: 'harvard_ats',
    );

    expect(bytes, isNotEmpty);
    // Standard PDF file header
    final header = ascii.decode(bytes.sublist(0, 5));
    expect(header, '%PDF-');
  });

  test('PdfExportServiceImpl generates valid English PDF bytes', () async {
    final service = PdfExportServiceImpl();
    final cv = CvModel.empty(id: 'test_pdf_cv_en');

    final bytes = await service.generateCvPdf(
      cv: cv,
      language: 'en',
      templateId: 'harvard_ats',
    );

    expect(bytes, isNotEmpty);
    final header = ascii.decode(bytes.sublist(0, 5));
    expect(header, '%PDF-');
  });

  test('PdfExportServiceImpl generates valid PDF bytes for 2-page Tuan Anh fullstack CV', () async {
    final service = PdfExportServiceImpl();
    final source = await rootBundle.loadString('assets/mock_cvs/tuananh_fullstack_cv.json');
    final cv = CvModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

    final bytes = await service.generateCvPdf(
      cv: cv,
      language: 'en',
      templateId: 'harvard_ats',
    );

    expect(bytes, isNotEmpty);
    final header = ascii.decode(bytes.sublist(0, 5));
    expect(header, '%PDF-');
    // Multi-page document has larger size than minimal 1-page skeleton
    expect(bytes.length, greaterThan(2500));
  });
}
