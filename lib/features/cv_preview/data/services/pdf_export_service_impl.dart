import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/skill_model.dart';
import '../../domain/services/pdf_export_service.dart';

class PdfExportServiceImpl implements PdfExportService {
  @override
  Future<Uint8List> generateCvPdf({
    required CvModel cv,
    required String language,
    String templateId = 'harvard_ats',
  }) async {
    final isEn = language == 'en';
    final scale = (cv.fontSizeScale > 0) ? cv.fontSizeScale : 1.0;

    final doc = pw.Document(
      title: cv.title.isNotEmpty ? cv.title : 'Curriculum Vitae',
      author: cv.personalInfo.fullName.isNotEmpty
          ? cv.personalInfo.fullName
          : 'CV Maker',
    );

    // Load Unicode-compatible fonts to support Vietnamese diacritics
    pw.Font fontRegular;
    pw.Font fontBold;
    pw.Font fontItalic;

    try {
      fontRegular = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
      fontItalic = await PdfGoogleFonts.robotoItalic();
    } catch (_) {
      // Fallback for offline or test environments
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
      fontItalic = pw.Font.helveticaOblique();
    }

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

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
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        theme: theme,
        build: (pw.Context context) {
          return [
            // Header: Name, Target Role, Contact
            pw.Center(
              child: pw.Text(
                fullName,
                style: pw.TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.1,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 3 * scale),
            pw.Center(
              child: pw.Text(
                targetRole,
                style: pw.TextStyle(
                  fontSize: 11 * scale,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#475569'),
                ),
              ),
            ),
            pw.SizedBox(height: 5 * scale),
            pw.Center(
              child: pw.Text(
                '$address • $phone • $email',
                style: pw.TextStyle(
                  fontSize: 9.5 * scale,
                  color: PdfColor.fromHex('#64748B'),
                ),
              ),
            ),
            pw.SizedBox(height: 10 * scale),
            pw.Divider(thickness: 1.2 * scale, color: PdfColors.black),
            pw.SizedBox(height: 8 * scale),

            // Section 1: Summary
            _buildPdfSectionHeader(
              isEn ? 'PROFESSIONAL SUMMARY' : 'TÓM TẮT MỤC TIÊU NGHỀ NGHIỆP',
              scale,
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

            // Section 2: Education
            _buildPdfSectionHeader(isEn ? 'EDUCATION' : 'HỌC VẤN', scale),
            pw.SizedBox(height: 4 * scale),
            if (cv.educations.isNotEmpty) ...[
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
            ] else ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      isEn
                          ? 'HANOI UNIVERSITY OF SCIENCE AND TECH'
                          : 'ĐẠI HỌC BÁCH KHOA HÀ NỘI',
                      style: pw.TextStyle(
                        fontSize: 10.5 * scale,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Text(
                    '2020 - 2024',
                    style: pw.TextStyle(
                      fontSize: 9.5 * scale,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
              pw.Text(
                isEn
                    ? 'Bachelor of Engineering in Computer Science — GPA: 3.6 / 4.0'
                    : 'Kỹ sư Công nghệ Thông tin - GPA: 3.6/4.0',
                style: pw.TextStyle(
                  fontSize: 9.5 * scale,
                  color: PdfColors.grey800,
                ),
              ),
            ],
            pw.SizedBox(height: 14 * scale),

            // Section 3: Work Experience & Projects
            _buildPdfSectionHeader(
              isEn
                  ? 'WORK EXPERIENCE & PROJECTS'
                  : 'KINH NGHIỆM LÀM VIỆC & DỰ ÁN',
              scale,
            ),
            pw.SizedBox(height: 4 * scale),
            if (cv.experiences.isNotEmpty) ...[
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
            ] else ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      isEn
                          ? 'TECH SOLUTIONS GLOBAL'
                          : 'CÔNG TY CỔ PHẦN CÔNG NGHỆ TECH',
                      style: pw.TextStyle(
                        fontSize: 10.5 * scale,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Text(
                    isEn ? '01/2023 - Present' : '01/2023 - Hiện tại',
                    style: pw.TextStyle(
                      fontSize: 9.5 * scale,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
              pw.Text(
                isEn
                    ? 'Lead Mobile & Fullstack Engineer'
                    : 'Kỹ sư phần mềm Flutter',
                style: pw.TextStyle(
                  fontSize: 9.5 * scale,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColor.fromHex('#334155'),
                ),
              ),
              pw.SizedBox(height: 3 * scale),
              _buildPdfBulletPoint(
                isEn
                    ? 'Architected production mobile app using Clean Architecture, Riverpod, and Drift SQLite.'
                    : 'Thiết kế kiến trúc Clean Architecture nhiều tầng tách biệt presentation, domain và data.',
                scale,
              ),
              _buildPdfBulletPoint(
                isEn
                    ? 'Engineered high-performance A4 vector PDF engine with automated pagination.'
                    : 'Tối ưu hóa công cụ render PDF A4 vector độ nét cao, ngăn chặn tràn trang thông minh.',
                scale,
              ),
              _buildPdfBulletPoint(
                isEn
                    ? 'Integrated Supabase Singapore Cloud backend with real-time replication.'
                    : 'Tích hợp xác thực và đồng bộ dữ liệu đám mây Supabase Singapore bảo mật cao.',
                scale,
              ),
            ],
            if (cv.projects.isNotEmpty) ...[
              pw.SizedBox(height: 14 * scale),
              _buildPdfSectionHeader(
                isEn ? 'KEY PROJECTS' : 'DỰ ÁN NỔI BẬT',
                scale,
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
                      if (proj.description.isNotEmpty) ...[
                        pw.SizedBox(height: 2 * scale),
                        pw.Text(
                          proj.description,
                          style: pw.TextStyle(
                            fontSize: 9.5 * scale,
                            lineSpacing: 1.5 * scale,
                            color: PdfColors.grey900,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
            pw.SizedBox(height: 14 * scale),

            // Section 4: Skills
            _buildPdfSectionHeader(
              isEn ? 'TECHNICAL & SOFT SKILLS' : 'KỸ NĂNG CHUYÊN MÔN & MỀM',
              scale,
            ),
            pw.SizedBox(height: 4 * scale),
            if (cv.skills.isNotEmpty) ...[
              _buildSkillsSection(cv.skills, isEn, scale),
            ] else ...[
              pw.Text(
                isEn
                    ? '• Languages & Frameworks: Flutter, Dart, TypeScript, Kotlin, SQL\n'
                        '• Backend & Cloud: Supabase, PostgreSQL, Row-Level Security, REST APIs\n'
                        '• Architecture & Tools: Clean Architecture, Riverpod, Git Flow, CI/CD, Vector PDF Engine'
                    : '• Ngôn ngữ & Framework: Flutter, Dart, TypeScript, Kotlin\n'
                        '• Backend & Database: Supabase, PostgreSQL, Row-Level Security, REST API\n'
                        '• Kiến trúc & Công cụ: Clean Architecture, Riverpod, Git Flow, Vector PDF Engine',
                style: pw.TextStyle(
                  fontSize: 9.5 * scale,
                  lineSpacing: 2 * scale,
                  color: PdfColors.grey900,
                ),
              ),
            ],
          ];
        },
      ),
    );

    return doc.save();
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

    // Also attempt saving to external Download folder on Android if possible
    try {
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final dlFile = File('${downloadDir.path}/$sanitizedName');
          await dlFile.writeAsBytes(bytes, flush: true);
        }
      }
    } catch (_) {
      // In case scoped storage restricts direct write, primaryFile is always safely stored
    }

    return primaryFile.path;
  }

  @override
  Future<void> shareOrSavePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final sanitizedName = _sanitizeFileName(fileName);
    await Printing.sharePdf(
      bytes: bytes,
      filename: sanitizedName,
    );
  }

  static pw.Widget _buildPdfSectionHeader(String title, double scale) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11 * scale,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.8,
            color: PdfColors.black,
          ),
        ),
        pw.Divider(color: PdfColors.black, thickness: 0.8 * scale),
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
}
