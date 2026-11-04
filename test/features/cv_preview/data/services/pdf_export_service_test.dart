import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_preview/data/services/pdf_export_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'PdfExportServiceImpl generates valid A4 PDF bytes starting with %PDF',
    () async {
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
    },
  );

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

  test('all free templates generate valid offline PDF documents', () async {
    final service = PdfExportServiceImpl();
    final cv = CvModel.empty(id: 'all-free-templates');

    for (final template in CvTemplateCatalog.freeTemplates) {
      final bytes = await service.generateCvPdf(
        cv: cv.copyWith(templateId: template.id),
        language: 'vi',
        templateId: template.id,
      );

      expect(bytes, isNotEmpty, reason: template.name);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-', reason: template.name);
    }
  });

  test('photo template embeds a local avatar without Internet', () async {
    final directory = await Directory.systemTemp.createTemp('cv-avatar-test-');
    addTearDown(() => directory.delete(recursive: true));
    final avatar = File('${directory.path}/avatar.png');
    await avatar.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );

    final service = PdfExportServiceImpl();
    final cv = CvModel.empty(id: 'photo-template').copyWith(
      templateId: 'creative_tech',
      personalInfo: PersonalInfoModel(avatarPath: avatar.path),
    );

    final bytes = await service.generateCvPdf(
      cv: cv,
      language: 'vi',
      templateId: 'creative_tech',
    );

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(2500));
  });

  test('photo template embeds a Web data URI avatar', () async {
    const avatarDataUri =
        'data:image/png;base64,'
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
    final cv = CvModel.empty(id: 'web-photo-template').copyWith(
      templateId: 'creative_tech',
      personalInfo: const PersonalInfoModel(avatarPath: avatarDataUri),
    );

    final bytes = await PdfExportServiceImpl().generateCvPdf(
      cv: cv,
      language: 'vi',
      templateId: cv.templateId,
    );

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(2500));
  });

  test('missing optional avatar does not block PDF export', () async {
    final service = PdfExportServiceImpl();
    final cv = CvModel.empty(id: 'missing-photo').copyWith(
      templateId: 'minimalist_clean',
      personalInfo: const PersonalInfoModel(
        avatarPath: 'Z:/this-file-does-not-exist.png',
      ),
    );

    final bytes = await service.generateCvPdf(
      cv: cv,
      language: 'vi',
      templateId: 'minimalist_clean',
    );

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  test(
    'PdfExportServiceImpl generates valid PDF bytes for 2-page Tuan Anh fullstack CV',
    () async {
      final service = PdfExportServiceImpl();
      final source = await rootBundle.loadString(
        'assets/mock_cvs/tuananh_fullstack_cv.json',
      );
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
    },
  );

  test('Trần Văn Hòa sample generates the 1/3–2/3 sidebar CV', () async {
    final source = await rootBundle.loadString(
      'assets/mock_cvs/tran_van_hoa_cv.json',
    );
    final cv = CvModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
    expect(cv.projects, hasLength(4));
    expect(cv.certifications.single.score, '700 / 990');

    final bytes = await PdfExportServiceImpl().generateCvPdf(
      cv: cv,
      language: 'vi',
      templateId: cv.templateId,
    );

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(4000));
  });

  test('sidebar template renders without a selected profile photo', () async {
    final cv = CvModel.empty(id: 'sidebar-initials').copyWith(
      templateId: 'professional_sidebar',
      personalInfo: const PersonalInfoModel(fullName: 'Trần Văn Hòa'),
    );

    final bytes = await PdfExportServiceImpl().generateCvPdf(
      cv: cv,
      language: 'vi',
      templateId: cv.templateId,
    );

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  test('PdfExportServiceImpl exports PDF successfully with customized sectionOrder', () async {
    final service = PdfExportServiceImpl();
    final cv = CvModel.empty(id: 'reordered-cv').copyWith(
      sectionOrder: [
        'projects',
        'skills',
        'education',
        'experience',
        'summary',
        'certifications',
      ],
    );
    final bytes = await service.generateCvPdf(
      cv: cv,
      language: 'vi',
      templateId: 'harvard_ats',
    );
    expect(bytes, isNotEmpty);
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
