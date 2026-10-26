import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/project_model.dart';
import '../../../cv_editor/domain/models/skill_model.dart';
import '../../domain/services/pdf_export_service.dart';

class PdfExportServiceImpl implements PdfExportService {
  static Future<_PdfFontSet>? _fontSetFuture;

  @override
  Future<Uint8List> generateCvPdf({
    required CvModel cv,
    required String language,
    String templateId = 'harvard_ats',
  }) async {
    final isEn = language == 'en';
    final scale = (cv.fontSizeScale > 0) ? cv.fontSizeScale : 1.0;
    final templateStyle = _TemplateStyle.fromId(templateId);

    final doc = pw.Document(
      title: cv.title.isNotEmpty ? cv.title : 'Curriculum Vitae',
      author: cv.personalInfo.fullName.isNotEmpty
          ? cv.personalInfo.fullName
          : 'CV Maker',
    );

    // Bundled Unicode fonts keep Vietnamese rendering deterministic and fully
    // offline. Falling back to Helvetica would silently drop diacritics.
    final fonts = await _loadBundledFonts();

    final theme = pw.ThemeData.withFont(
      base: fonts.regular,
      bold: fonts.bold,
      italic: fonts.regular,
    );
    final avatarImage = await _loadAvatarImage(
      cv.personalInfo.avatarPath,
      enabled: templateStyle.showPhoto,
    );

    if (templateId == 'professional_sidebar') {
      _addProfessionalSidebarPage(
        doc: doc,
        cv: cv,
        theme: theme,
        avatarImage: avatarImage,
        isEn: isEn,
        scale: scale,
      );
      return doc.save();
    }

    // Personal Info Resolvers
    final fullName = cv.personalInfo.fullName.isNotEmpty
        ? cv.personalInfo.fullName.toUpperCase()
        : (isEn ? 'TUAN ANH NGUYEN' : 'NGUYỄN TUẤN ANH');

    final targetRole = cv.personalInfo.targetRole.isNotEmpty
        ? cv.personalInfo.targetRole.toUpperCase()
        : (isEn ? 'FULLSTACK SOFTWARE ENGINEER' : 'KỸ SƯ PHẦN MỀM FLUTTER');

    final address = cv.personalInfo.address.isNotEmpty
        ? cv.personalInfo.address
        : (isEn ? 'Hanoi, Vietnam' : 'Hà Nội, Việt Nam');

    final phone = cv.personalInfo.phone.isNotEmpty
        ? cv.personalInfo.phone
        : '0901 234 567';

    final email = cv.personalInfo.email.isNotEmpty
        ? cv.personalInfo.email
        : 'tuananh@example.com';

    final summary = cv.summary.isNotEmpty
        ? cv.summary
        : (isEn
              ? 'Results-driven Fullstack Software Engineer specializing in cross-platform mobile architectures with Flutter, Dart, Clean Architecture, and Riverpod. Proven track record in engineering offline-first SQLite databases, vector PDF document rendering engines, and scalable Supabase cloud integrations.'
              : 'Kỹ sư phần mềm mobile chuyên sâu về Flutter, kiến trúc Clean Architecture, State Management (Riverpod) và tích hợp Backend-as-a-Service (Supabase). Đam mê tối ưu hóa trải nghiệm người dùng và xây dựng hệ thống bền vững.');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: templateStyle.pageMargin,
        theme: theme,
        build: (pw.Context context) {
          return [
            // Header: Name, Target Role, Contact
            _buildPdfHeader(
              fullName: fullName,
              targetRole: targetRole,
              contact: '$address • $phone • $email',
              scale: scale,
              style: templateStyle,
              avatarImage: avatarImage,
              avatarPosition: cv.personalInfo.avatarPosition,
            ),
            pw.SizedBox(height: 8 * scale),

            // Section 1: Summary
            _buildPdfSectionHeader(
              isEn ? 'PROFESSIONAL SUMMARY' : 'TÓM TẮT MỤC TIÊU NGHỀ NGHIỆP',
              scale,
              templateStyle,
            ),
            pw.SizedBox(height: 4 * scale),
            pw.Text(
              summary,
              style: pw.TextStyle(
                fontSize: 10 * scale,
                lineSpacing: 2 * scale,
                color: PdfColors.grey900,
              ),
            ),
            pw.SizedBox(height: 14 * scale),

            if (cv.educations.isNotEmpty) ...[
              _buildPdfSectionHeader(
                isEn ? 'EDUCATION' : 'HỌC VẤN',
                scale,
                templateStyle,
              ),
              pw.SizedBox(height: 4 * scale),
              ...cv.educations.map((edu) {
                final startYear = edu.startDate.year;
                final endYear = edu.isCurrent
                    ? (isEn ? 'Present' : 'Hiện tại')
                    : (edu.endDate?.year.toString() ?? '');
                final period = '$startYear - $endYear';

                return pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 6 * scale),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              edu.institution.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 10.5 * scale,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            period,
                            style: pw.TextStyle(
                              fontSize: 9.5 * scale,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        '${edu.degree} — ${edu.fieldOfStudy}${edu.gpa != null ? " (GPA: ${edu.gpa})" : ""}',
                        style: pw.TextStyle(
                          fontSize: 9.5 * scale,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (cv.educations.isNotEmpty) pw.SizedBox(height: 14 * scale),

            // Section 3: Work Experience & Projects
            if (cv.experiences.isNotEmpty) ...[
              _buildPdfSectionHeader(
                isEn ? 'WORK EXPERIENCE' : 'KINH NGHIỆM LÀM VIỆC',
                scale,
                templateStyle,
              ),
              pw.SizedBox(height: 4 * scale),
              ...cv.experiences.map((exp) {
                final startStr =
                    '${exp.startDate.month.toString().padLeft(2, '0')}/${exp.startDate.year}';
                final endStr = exp.isCurrent
                    ? (isEn ? 'Present' : 'Hiện tại')
                    : (exp.endDate != null
                          ? '${exp.endDate!.month.toString().padLeft(2, '0')}/${exp.endDate!.year}'
                          : '');
                final period = '$startStr - $endStr';

                return pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 8 * scale),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              exp.company.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 10.5 * scale,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            period,
                            style: pw.TextStyle(
                              fontSize: 9.5 * scale,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        exp.location.isNotEmpty
                            ? '${exp.jobTitle} • ${exp.location}'
                            : exp.jobTitle,
                        style: pw.TextStyle(
                          fontSize: 9.5 * scale,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColor.fromHex('#334155'),
                        ),
                      ),
                      pw.SizedBox(height: 2 * scale),
                      ...exp.bulletPoints.map(
                        (b) => pw.Padding(
                          padding: pw.EdgeInsets.only(bottom: 2 * scale),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                '• ',
                                style: pw.TextStyle(
                                  fontSize: 9.5 * scale,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  b,
                                  style: pw.TextStyle(
                                    fontSize: 9.5 * scale,
                                    lineSpacing: 1.5 * scale,
                                    color: PdfColors.grey900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (cv.projects.isNotEmpty) ...[
              pw.SizedBox(height: 14 * scale),
              _buildPdfSectionHeader(
                isEn ? 'KEY PROJECTS' : 'DỰ ÁN NỔI BẬT',
                scale,
                templateStyle,
              ),
              pw.SizedBox(height: 4 * scale),
              ...cv.projects.map((proj) {
                final dateStr = (proj.startDate != null)
                    ? '${proj.startDate!.month.toString().padLeft(2, '0')}/${proj.startDate!.year} - '
                          '${proj.endDate != null ? "${proj.endDate!.month.toString().padLeft(2, '0')}/${proj.endDate!.year}" : (isEn ? "Present" : "Hiện tại")}'
                    : '';
                return pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 8 * scale),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              proj.name,
                              style: pw.TextStyle(
                                fontSize: 10.5 * scale,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          if (dateStr.isNotEmpty)
                            pw.Text(
                              dateStr,
                              style: pw.TextStyle(
                                fontSize: 9.5 * scale,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      if (proj.role.isNotEmpty || proj.technologies.isNotEmpty)
                        pw.Text(
                          [
                            if (proj.role.isNotEmpty) proj.role,
                            if (proj.teamSize != null)
                              isEn
                                  ? 'Team of ${proj.teamSize}'
                                  : 'Nhóm ${proj.teamSize} người',
                            if (proj.technologies.isNotEmpty)
                              proj.technologies.join(', '),
                          ].join(' | '),
                          style: pw.TextStyle(
                            fontSize: 9.5 * scale,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColor.fromHex('#334155'),
                          ),
                        ),
                      if (proj.sourceUrl != null && proj.sourceUrl!.isNotEmpty)
                        pw.Text(
                          proj.sourceUrl!,
                          style: pw.TextStyle(
                            fontSize: 9 * scale,
                            color: PdfColor.fromHex('#2563EB'),
                          ),
                        ),
                      if (proj.demoUrl != null && proj.demoUrl!.isNotEmpty)
                        pw.Text(
                          proj.demoUrl!,
                          style: pw.TextStyle(
                            fontSize: 9 * scale,
                            color: PdfColor.fromHex('#2563EB'),
                          ),
                        ),
                      if (proj.description.isNotEmpty) ...[
                        pw.SizedBox(height: 2 * scale),
                        ...proj.description
                            .split('\n')
                            .map((line) => line.trim())
                            .where((line) => line.isNotEmpty)
                            .map((line) => _buildPdfBulletPoint(line, scale)),
                      ],
                    ],
                  ),
                );
              }),
            ],
            if (cv.certifications.isNotEmpty) ...[
              pw.SizedBox(height: 10 * scale),
              _buildPdfSectionHeader(
                isEn ? 'CERTIFICATIONS' : 'CHỨNG CHỈ',
                scale,
                templateStyle,
              ),
              pw.SizedBox(height: 4 * scale),
              ...cv.certifications.map(
                (cert) => pw.Text(
                  '• ${cert.name}${cert.score?.isNotEmpty == true ? " — ${cert.score}" : ""}${cert.issuer.isNotEmpty ? " • ${cert.issuer}" : ""}',
                  style: pw.TextStyle(fontSize: 9.5 * scale),
                ),
              ),
            ],
            if (cv.skills.isNotEmpty) pw.SizedBox(height: 14 * scale),

            // Section 4: Skills
            if (cv.skills.isNotEmpty) ...[
              _buildPdfSectionHeader(
                isEn ? 'TECHNICAL & SOFT SKILLS' : 'KỸ NĂNG CHUYÊN MÔN & MỀM',
                scale,
                templateStyle,
              ),
              pw.SizedBox(height: 4 * scale),
              _buildSkillsSection(cv.skills, isEn, scale),
            ],
          ];
        },
      ),
    );

    return doc.save();
  }

  static void _addProfessionalSidebarPage({
    required pw.Document doc,
    required CvModel cv,
    required pw.ThemeData theme,
    required pw.MemoryImage? avatarImage,
    required bool isEn,
    required double scale,
  }) {
    final navy = PdfColor.fromHex('#16324F');
    final teal = PdfColor.fromHex('#18A999');
    final small = 9.2 * scale;
    final nameParts = cv.personalInfo.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = nameParts.isEmpty
        ? 'CV'
        : nameParts.length == 1
        ? nameParts.first.substring(0, 1).toUpperCase()
        : '${nameParts.first.substring(0, 1)}${nameParts.last.substring(0, 1)}'
              .toUpperCase();
    pw.Widget heading(String value, {bool light = false}) => pw.Padding(
      padding: pw.EdgeInsets.only(top: 7 * scale, bottom: 3 * scale),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 11.5 * scale,
          fontWeight: pw.FontWeight.bold,
          color: light ? PdfColors.white : navy,
        ),
      ),
    );
    pw.Widget bullet(String value) => pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 2.5 * scale),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '• ',
            style: pw.TextStyle(fontSize: small, color: teal),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: small, lineSpacing: 1.5 * scale),
            ),
          ),
        ],
      ),
    );
    String period(DateTime? start, DateTime? end) => start == null
        ? ''
        : '${start.month.toString().padLeft(2, '0')}/${start.year} – ${end == null ? (isEn ? 'Present' : 'Nay') : '${end.month.toString().padLeft(2, '0')}/${end.year}'}';
    pw.Widget project(ProjectModel item) => pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 8 * scale),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  item.name,
                  style: pw.TextStyle(
                    fontSize: 10.5 * scale,
                    fontWeight: pw.FontWeight.bold,
                    color: navy,
                  ),
                ),
              ),
              pw.Text(
                period(item.startDate, item.endDate),
                style: pw.TextStyle(
                  fontSize: 8.2 * scale,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
          pw.Text(
            [
              item.role,
              if (item.teamSize != null)
                (isEn
                    ? 'Team ${item.teamSize}'
                    : 'Nhóm ${item.teamSize} người'),
              if (item.technologies.isNotEmpty) item.technologies.join(', '),
            ].where((e) => e.isNotEmpty).join(' | '),
            style: pw.TextStyle(
              fontSize: 8.6 * scale,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          if (item.sourceUrl?.isNotEmpty == true)
            pw.Text(
              item.sourceUrl!,
              style: pw.TextStyle(
                fontSize: 8 * scale,
                color: PdfColors.blue700,
              ),
            ),
          ...item.description
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map(bullet),
        ],
      ),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: theme,
        build: (_) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              width: PdfPageFormat.a4.width / 3,
              color: navy,
              padding: pw.EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 24 * scale,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: avatarImage != null
                        ? pw.ClipOval(
                            child: pw.Container(
                              width: 78 * scale,
                              height: 78 * scale,
                              child: pw.Image(
                                avatarImage,
                                fit: pw.BoxFit.cover,
                              ),
                            ),
                          )
                        : pw.Container(
                            width: 78 * scale,
                            height: 78 * scale,
                            alignment: pw.Alignment.center,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: PdfColors.white,
                              border: pw.Border.all(color: teal, width: 2),
                            ),
                            child: pw.Text(
                              initials,
                              style: pw.TextStyle(
                                fontSize: 24 * scale,
                                fontWeight: pw.FontWeight.bold,
                                color: navy,
                              ),
                            ),
                          ),
                  ),
                  heading(isEn ? 'CONTACT' : 'LIÊN HỆ', light: true),
                  ...[
                        cv.personalInfo.email,
                        cv.personalInfo.phone,
                        cv.personalInfo.address,
                        cv.personalInfo.githubUrl ?? '',
                        cv.personalInfo.linkedInUrl ?? '',
                      ]
                      .where((e) => e.isNotEmpty)
                      .map(
                        (e) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: pw.Text(
                            e,
                            style: pw.TextStyle(
                              fontSize: small,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ),
                  if (cv.educations.isNotEmpty) ...[
                    heading(isEn ? 'EDUCATION' : 'HỌC VẤN', light: true),
                    ...cv.educations.map(
                      (e) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              e.institution,
                              style: pw.TextStyle(
                                fontSize: 9.5 * scale,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              '${e.fieldOfStudy}\n${e.startDate.year} – ${e.endDate?.year ?? 2027}${e.gpa == null ? '' : '\nGPA: ${e.gpa}'}',
                              style: pw.TextStyle(
                                fontSize: small,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (cv.certifications.isNotEmpty) ...[
                    heading(isEn ? 'CERTIFICATIONS' : 'CHỨNG CHỈ', light: true),
                    ...cv.certifications.map(
                      (e) => pw.Text(
                        '• ${e.name}${e.score?.isNotEmpty == true ? ' ${e.score}' : ''}',
                        style: pw.TextStyle(
                          fontSize: small,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                  if (cv.skills.isNotEmpty) ...[
                    heading(isEn ? 'SKILLS' : 'KỸ NĂNG', light: true),
                    ...cv.skills.map(
                      (e) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Text(
                          '• ${e.name}',
                          style: pw.TextStyle(
                            fontSize: small,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Padding(
                padding: pw.EdgeInsets.symmetric(
                  horizontal: 20 * scale,
                  vertical: 24 * scale,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      cv.personalInfo.fullName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 23 * scale,
                        fontWeight: pw.FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    pw.Text(
                      cv.personalInfo.targetRole.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 11.5 * scale,
                        fontWeight: pw.FontWeight.bold,
                        color: teal,
                      ),
                    ),
                    if (cv.summary.isNotEmpty) ...[
                      heading(isEn ? 'PROFILE' : 'MỤC TIÊU NGHỀ NGHIỆP'),
                      pw.Text(
                        cv.summary,
                        style: pw.TextStyle(
                          fontSize: small,
                          lineSpacing: 1.6 * scale,
                        ),
                      ),
                    ],
                    if (cv.experiences.isNotEmpty) ...[
                      heading(isEn ? 'EXPERIENCE' : 'KINH NGHIỆM'),
                      ...cv.experiences.map(
                        (e) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 5),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Expanded(
                                    child: pw.Text(
                                      '${e.jobTitle} — ${e.company}',
                                      style: pw.TextStyle(
                                        fontSize: 10.5 * scale,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  pw.Text(
                                    period(e.startDate, e.endDate),
                                    style: pw.TextStyle(fontSize: 8.2 * scale),
                                  ),
                                ],
                              ),
                              ...e.bulletPoints.map(bullet),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (cv.projects.isNotEmpty) ...[
                      heading(isEn ? 'PROJECTS' : 'DỰ ÁN'),
                      ...cv.projects.map(project),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<String> savePdfLocally({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final sanitizedName = _sanitizeFileName(fileName);
    final appDir = await getApplicationDocumentsDirectory();
    final primaryFile = File('${appDir.path}/$sanitizedName');
    await primaryFile.writeAsBytes(bytes, flush: true);
    var savedPath = primaryFile.path;

    // Also attempt saving to external Download folder on Android if possible
    try {
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final dlFile = File('${downloadDir.path}/$sanitizedName');
          await dlFile.writeAsBytes(bytes, flush: true);
          savedPath = dlFile.path;
        }
      }
    } catch (_) {
      // In case scoped storage restricts direct write, primaryFile is always safely stored
    }

    return savedPath;
  }

  @override
  Future<void> shareOrSavePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final sanitizedName = _sanitizeFileName(fileName);
    await Printing.sharePdf(bytes: bytes, filename: sanitizedName);
  }

  static pw.Widget _buildPdfHeader({
    required String fullName,
    required String targetRole,
    required String contact,
    required double scale,
    required _TemplateStyle style,
    pw.MemoryImage? avatarImage,
    String avatarPosition = 'right',
  }) {
    final content = pw.Column(
      crossAxisAlignment: style.centerHeader
          ? pw.CrossAxisAlignment.center
          : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          fullName,
          style: pw.TextStyle(
            fontSize: style.nameSize * scale,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: style.letterSpacing,
            color: style.primary,
          ),
        ),
        pw.SizedBox(height: 3 * scale),
        pw.Text(
          targetRole,
          style: pw.TextStyle(
            fontSize: 12.5 * scale,
            fontWeight: pw.FontWeight.bold,
            color: style.accent,
          ),
        ),
        pw.SizedBox(height: 5 * scale),
        pw.Text(
          contact,
          textAlign: style.centerHeader
              ? pw.TextAlign.center
              : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: 9.5 * scale,
            color: PdfColor.fromHex('#64748B'),
          ),
        ),
      ],
    );

    final photo = avatarImage == null
        ? null
        : pw.ClipOval(
            child: pw.Container(
              width: 68 * scale,
              height: 68 * scale,
              child: pw.Image(avatarImage, fit: pw.BoxFit.cover),
            ),
          );
    final headerContent = photo == null
        ? content
        : pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: avatarPosition == 'left'
                ? [
                    photo,
                    pw.SizedBox(width: 14 * scale),
                    pw.Expanded(child: content),
                  ]
                : [
                    pw.Expanded(child: content),
                    pw.SizedBox(width: 14 * scale),
                    photo,
                  ],
          );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (style.headerFill != null)
          pw.Container(
            padding: pw.EdgeInsets.all(12 * scale),
            decoration: pw.BoxDecoration(
              color: style.headerFill,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: headerContent,
          )
        else if (style.centerHeader)
          pw.Center(child: headerContent)
        else
          headerContent,
        pw.SizedBox(height: 10 * scale),
        pw.Container(height: 2 * scale, color: style.accent),
      ],
    );
  }

  static pw.Widget _buildPdfSectionHeader(
    String title,
    double scale,
    _TemplateStyle style,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11 * scale,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.8,
            color: style.primary,
          ),
        ),
        pw.Divider(
          color: style.accent,
          thickness: style.dividerThickness * scale,
        ),
      ],
    );
  }

  static pw.Widget _buildPdfBulletPoint(String text, double scale) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 2 * scale),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '• ',
            style: pw.TextStyle(
              fontSize: 9.5 * scale,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 9.5 * scale,
                lineSpacing: 1.5 * scale,
                color: PdfColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSkillsSection(
    List<SkillModel> skills,
    bool isEn,
    double scale,
  ) {
    final hard = skills
        .where((s) => s.category == SkillCategory.hard)
        .map((s) => s.name)
        .join(', ');
    final soft = skills
        .where((s) => s.category == SkillCategory.soft)
        .map((s) => s.name)
        .join(', ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (hard.isNotEmpty)
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: 2 * scale),
            child: pw.Text(
              '• ${isEn ? "Technical & Frameworks: " : "Kỹ năng chuyên môn: "}$hard',
              style: pw.TextStyle(
                fontSize: 9.5 * scale,
                lineSpacing: 1.8 * scale,
                color: PdfColors.grey900,
              ),
            ),
          ),
        if (soft.isNotEmpty)
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: 2 * scale),
            child: pw.Text(
              '• ${isEn ? "Methodologies & Soft Skills: " : "Kỹ năng mềm & Phương pháp: "}$soft',
              style: pw.TextStyle(
                fontSize: 9.5 * scale,
                lineSpacing: 1.8 * scale,
                color: PdfColors.grey900,
              ),
            ),
          ),
      ],
    );
  }

  static String _sanitizeFileName(String name) {
    var clean = name.trim();
    if (clean.isEmpty) clean = 'CV_Document';
    // Remove invalid filename characters
    clean = clean.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (!clean.toLowerCase().endsWith('.pdf')) {
      clean = '$clean.pdf';
    }
    return clean;
  }

  static Future<_PdfFontSet> _loadBundledFonts() {
    return _fontSetFuture ??= (() async {
      final regularData = await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      );
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');

      return _PdfFontSet(
        regular: pw.Font.ttf(regularData),
        bold: pw.Font.ttf(boldData),
      );
    })();
  }

  static Future<pw.MemoryImage?> _loadAvatarImage(
    String? avatarPath, {
    required bool enabled,
  }) async {
    if (!enabled || avatarPath == null || avatarPath.trim().isEmpty) {
      return null;
    }
    try {
      final file = File(avatarPath);
      if (!await file.exists()) return null;
      return pw.MemoryImage(await file.readAsBytes());
    } catch (_) {
      // A missing or damaged optional photo must never block PDF export.
      return null;
    }
  }
}

final class _TemplateStyle {
  const _TemplateStyle({
    required this.primary,
    required this.accent,
    required this.pageMargin,
    required this.centerHeader,
    required this.nameSize,
    required this.letterSpacing,
    required this.dividerThickness,
    required this.showPhoto,
    this.headerFill,
  });

  final PdfColor primary;
  final PdfColor accent;
  final pw.EdgeInsets pageMargin;
  final bool centerHeader;
  final double nameSize;
  final double letterSpacing;
  final double dividerThickness;
  final bool showPhoto;
  final PdfColor? headerFill;

  factory _TemplateStyle.fromId(String templateId) {
    switch (templateId) {
      case 'modern_minimalist':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#0F172A'),
          accent: PdfColor.fromHex('#2563EB'),
          pageMargin: const pw.EdgeInsets.symmetric(
            horizontal: 38,
            vertical: 34,
          ),
          centerHeader: false,
          nameSize: 20,
          letterSpacing: 0.4,
          dividerThickness: 1.2,
          showPhoto: false,
        );
      case 'minimalist_clean':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#134E4A'),
          accent: PdfColor.fromHex('#0F766E'),
          pageMargin: const pw.EdgeInsets.symmetric(
            horizontal: 42,
            vertical: 38,
          ),
          centerHeader: false,
          nameSize: 19,
          letterSpacing: 0.2,
          dividerThickness: 0.55,
          showPhoto: true,
        );
      case 'creative_tech':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#312E81'),
          accent: PdfColor.fromHex('#7C3AED'),
          headerFill: PdfColor.fromHex('#F5F3FF'),
          pageMargin: const pw.EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 30,
          ),
          centerHeader: false,
          nameSize: 21,
          letterSpacing: 0.3,
          dividerThickness: 1.4,
          showPhoto: true,
        );
      case 'professional_sidebar':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#16324F'),
          accent: PdfColor.fromHex('#18A999'),
          pageMargin: pw.EdgeInsets.zero,
          centerHeader: false,
          nameSize: 20,
          letterSpacing: 0.2,
          dividerThickness: 1,
          showPhoto: true,
        );
      case 'executive_navy':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#172554'),
          accent: PdfColor.fromHex('#1E3A8A'),
          pageMargin: const pw.EdgeInsets.symmetric(
            horizontal: 38,
            vertical: 32,
          ),
          centerHeader: false,
          nameSize: 21,
          letterSpacing: 0.5,
          dividerThickness: 1.5,
          showPhoto: false,
        );
      case 'academic_classic':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#431407'),
          accent: PdfColor.fromHex('#9A3412'),
          pageMargin: const pw.EdgeInsets.symmetric(
            horizontal: 44,
            vertical: 38,
          ),
          centerHeader: true,
          nameSize: 19,
          letterSpacing: 0.8,
          dividerThickness: 0.65,
          showPhoto: false,
        );
      case 'fresh_profile':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#064E3B'),
          accent: PdfColor.fromHex('#047857'),
          headerFill: PdfColor.fromHex('#ECFDF5'),
          pageMargin: const pw.EdgeInsets.symmetric(
            horizontal: 34,
            vertical: 31,
          ),
          centerHeader: false,
          nameSize: 20,
          letterSpacing: 0.25,
          dividerThickness: 1.1,
          showPhoto: true,
        );
      default:
        return const _TemplateStyle(
          primary: PdfColors.black,
          accent: PdfColors.black,
          pageMargin: pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
          centerHeader: true,
          nameSize: 18,
          letterSpacing: 1.1,
          dividerThickness: 0.8,
          showPhoto: false,
        );
    }
  }
}

class _PdfFontSet {
  const _PdfFontSet({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}
