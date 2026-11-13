import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/project_model.dart';
import '../../../cv_editor/domain/models/skill_model.dart';
import '../../domain/services/pdf_export_service.dart';
import 'pdf_platform_storage.dart' as platform;
import '../../../cv_editor/domain/services/cv_bullet_cleaner.dart';

class PdfExportServiceImpl implements PdfExportService {
  static Future<_PdfFontSet>? _fontSetFuture;

  @override
  Future<Uint8List> generateCvPdf({
    required CvModel cv,
    required String language,
    String templateId = 'harvard_ats',
  }) async {
    cv = CvBulletCleaner.clean(cv);
    final isEn = language == 'en';
    final scale = (cv.fontSizeScale > 0) ? cv.fontSizeScale : 1.0;
    final templateStyle = _TemplateStyle.fromId(
      templateId,
      customPrimaryHex: cv.primaryColor,
    );

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
        : (isEn ? 'YOUR NAME' : 'HỌ VÀ TÊN');

    final targetRole = cv.personalInfo.targetRole.isNotEmpty
        ? cv.personalInfo.targetRole.toUpperCase()
        : (isEn ? 'TARGET ROLE' : 'VỊ TRÍ ỨNG TUYỂN');

    final contact = [
      cv.personalInfo.address,
      cv.personalInfo.phone,
      cv.personalInfo.email,
    ].where((value) => value.trim().isNotEmpty).join(' • ');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: templateStyle.pageMargin,
        theme: theme,
        build: (pw.Context context) {
          final summaryWidgets = <pw.Widget>[
            if (cv.summary.trim().isNotEmpty) ...[
              _buildPdfSectionHeader(
                isEn ? 'PROFESSIONAL SUMMARY' : 'TÓM TẮT MỤC TIÊU NGHỀ NGHIỆP',
                scale,
                templateStyle,
              ),
              pw.SizedBox(height: 4 * scale),
              pw.Text(
                cv.summary,
                style: pw.TextStyle(
                  fontSize: 10 * scale,
                  lineSpacing: 2 * scale,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 14 * scale),
            ],
          ];

          final educationWidgets = <pw.Widget>[
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
              pw.SizedBox(height: 14 * scale),
            ],
          ];

          final experienceWidgets = <pw.Widget>[
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
              pw.SizedBox(height: 14 * scale),
            ],
          ];

          final projectsWidgets = <pw.Widget>[
            if (cv.projects.isNotEmpty) ...[
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
              pw.SizedBox(height: 14 * scale),
            ],
          ];

          final skillsWidgets = <pw.Widget>[
            if (cv.skills.isNotEmpty) ...[
              _buildPdfSectionHeader(
                isEn ? 'TECHNICAL & SOFT SKILLS' : 'KỸ NĂNG CHUYÊN MÔN & MỀM',
                scale,
                templateStyle,
              ),
              pw.SizedBox(height: 4 * scale),
              _buildSkillsSection(cv.skills, isEn, scale),
              pw.SizedBox(height: 14 * scale),
            ],
          ];

          final certificationsWidgets = <pw.Widget>[
            if (cv.certifications.isNotEmpty) ...[
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
              pw.SizedBox(height: 14 * scale),
            ],
          ];

          final sectionMap = <String, List<pw.Widget>>{
            'summary': summaryWidgets,
            'experience': experienceWidgets,
            'projects': projectsWidgets,
            'education': educationWidgets,
            'skills': skillsWidgets,
            'certifications': certificationsWidgets,
          };

          final orderedSections = <pw.Widget>[
            _buildPdfHeader(
              fullName: fullName,
              targetRole: targetRole,
              contact: contact,
              scale: scale,
              style: templateStyle,
              avatarImage: avatarImage,
              avatarPosition: cv.personalInfo.avatarPosition,
            ),
            pw.SizedBox(height: 8 * scale),
          ];

          for (final sectionKey in cv.visibleSectionOrder) {
            final widgets = sectionMap[sectionKey];
            if (widgets != null && widgets.isNotEmpty) {
              orderedSections.addAll(widgets);
            }
          }

          return orderedSections;
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
    return platform.savePdfBytes(bytes, sanitizedName);
  }

  @override
  Future<void> shareOrSavePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final sanitizedName = _sanitizeFileName(fileName);
    await platform.sharePdfBytes(bytes, sanitizedName);
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
      final bytes = await platform.loadAvatarBytes(avatarPath);
      return bytes == null ? null : pw.MemoryImage(bytes);
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

  _TemplateStyle copyWith({
    PdfColor? primary,
    PdfColor? accent,
    pw.EdgeInsets? pageMargin,
    bool? centerHeader,
    double? nameSize,
    double? letterSpacing,
    double? dividerThickness,
    bool? showPhoto,
    PdfColor? headerFill,
  }) {
    return _TemplateStyle(
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      pageMargin: pageMargin ?? this.pageMargin,
      centerHeader: centerHeader ?? this.centerHeader,
      nameSize: nameSize ?? this.nameSize,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      dividerThickness: dividerThickness ?? this.dividerThickness,
      showPhoto: showPhoto ?? this.showPhoto,
      headerFill: headerFill ?? this.headerFill,
    );
  }

  factory _TemplateStyle.fromId(String templateId, {String? customPrimaryHex}) {
    final base = _resolveBaseStyle(templateId);
    if (customPrimaryHex != null && customPrimaryHex.trim().isNotEmpty) {
      try {
        final clean = customPrimaryHex.replaceAll('#', '');
        if (clean.length == 6) {
          final customColor = PdfColor.fromHex('#$clean');
          return base.copyWith(primary: customColor);
        }
      } catch (_) {}
    }
    return base;
  }

  /// Premium designs are built on an existing layout.
  static const _premiumBases = {
    'premium_elegant_photo': 'minimalist_clean',
    'premium_creative_portfolio': 'creative_tech',
    'premium_ai_focus': 'executive_navy',
  };

  static _TemplateStyle _resolveBaseStyle(String requestedId) {
    final templateId = _premiumBases[requestedId] ?? requestedId;
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
      case 'chronological_slate':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#0F172A'),
          accent: PdfColor.fromHex('#334155'),
          pageMargin: const pw.EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 34,
          ),
          centerHeader: false,
          nameSize: 20,
          letterSpacing: 0.35,
          dividerThickness: 1,
          showPhoto: false,
        );
      case 'graduate_skills':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#0C4A6E'),
          accent: PdfColor.fromHex('#0369A1'),
          headerFill: PdfColor.fromHex('#F0F9FF'),
          pageMargin: const pw.EdgeInsets.symmetric(
            horizontal: 34,
            vertical: 30,
          ),
          centerHeader: false,
          nameSize: 21,
          letterSpacing: 0.2,
          dividerThickness: 1.15,
          showPhoto: false,
        );
      case 'finance_precision':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#0F2742'),
          accent: PdfColor.fromHex('#1E3A5F'),
          pageMargin: const pw.EdgeInsets.symmetric(
            horizontal: 42,
            vertical: 34,
          ),
          centerHeader: true,
          nameSize: 20,
          letterSpacing: 0.7,
          dividerThickness: 1.35,
          showPhoto: false,
        );
      case 'healthcare_calm':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#134E4A'),
          accent: PdfColor.fromHex('#0F766E'),
          headerFill: PdfColor.fromHex('#F0FDFA'),
          pageMargin: const pw.EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 36,
          ),
          centerHeader: false,
          nameSize: 19.5,
          letterSpacing: 0.2,
          dividerThickness: 0.75,
          showPhoto: false,
        );
      case 'sales_impact':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#451A03'),
          accent: PdfColor.fromHex('#B45309'),
          headerFill: PdfColor.fromHex('#FFF7ED'),
          pageMargin: const pw.EdgeInsets.symmetric(
            horizontal: 36,
            vertical: 31,
          ),
          centerHeader: false,
          nameSize: 21,
          letterSpacing: 0.3,
          dividerThickness: 1.4,
          showPhoto: false,
        );
      case 'international_compact':
        return _TemplateStyle(
          primary: PdfColor.fromHex('#111827'),
          accent: PdfColor.fromHex('#111827'),
          pageMargin: const pw.EdgeInsets.symmetric(
            horizontal: 34,
            vertical: 28,
          ),
          centerHeader: true,
          nameSize: 18.5,
          letterSpacing: 0.8,
          dividerThickness: 0.65,
          showPhoto: false,
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
