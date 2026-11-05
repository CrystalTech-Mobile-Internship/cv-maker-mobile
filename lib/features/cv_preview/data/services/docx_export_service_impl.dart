import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../cv_editor/domain/models/cv_model.dart';
import '../../domain/repositories/document_export_repository.dart';

class DocxExportServiceImpl implements DocumentExportRepository {
  const DocxExportServiceImpl();

  @override
  Future<Uint8List> generateDocx({
    required CvModel cv,
    required String language,
  }) async {
    final isEn = language == 'en';
    final buffer = StringBuffer();

    // Start document
    buffer.write(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:body>',
    );

    // Header: Name
    final fullName = cv.personalInfo.fullName.trim().isNotEmpty
        ? cv.personalInfo.fullName
        : (isEn ? 'YOUR NAME' : 'HỌ VÀ TÊN');
    buffer.write(
      '<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:after="60"/></w:pPr>'
      '<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="40"/><w:color w:val="1E293B"/></w:rPr>'
      '<w:t>${_escapeXml(fullName.toUpperCase())}</w:t></w:r></w:p>',
    );

    // Target Role
    if (cv.personalInfo.targetRole.trim().isNotEmpty) {
      buffer.write(
        '<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:after="80"/></w:pPr>'
        '<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="24"/><w:color w:val="4338CA"/></w:rPr>'
        '<w:t>${_escapeXml(cv.personalInfo.targetRole.toUpperCase())}</w:t></w:r></w:p>',
      );
    }

    // Contact info
    final contactParts = [
      cv.personalInfo.phone,
      cv.personalInfo.email,
      cv.personalInfo.address,
    ].where((part) => part.trim().isNotEmpty).toList();

    if (contactParts.isNotEmpty) {
      buffer.write(
        '<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:after="200"/></w:pPr>'
        '<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="19"/><w:color w:val="64748B"/></w:rPr>'
        '<w:t>${_escapeXml(contactParts.join('  •  '))}</w:t></w:r></w:p>',
      );
    }

    // Dynamic sections based on user-ordered sequence
    for (final sectionId in cv.visibleSectionOrder) {
      switch (sectionId) {
        case 'summary':
          if (cv.summary.trim().isNotEmpty) {
            buffer.write(_buildHeading(isEn ? 'PROFESSIONAL SUMMARY' : 'MỤC TIÊU NGHỀ NGHIỆP'));
            buffer.write(_buildParagraph(cv.summary));
          }
          break;

        case 'experience':
          if (cv.experiences.isNotEmpty) {
            buffer.write(_buildHeading(isEn ? 'WORK EXPERIENCE' : 'KINH NGHIỆM LÀM VIỆC'));
            for (final exp in cv.experiences) {
              final startStr = '${exp.startDate.month.toString().padLeft(2, '0')}/${exp.startDate.year}';
              final endStr = exp.isCurrent
                  ? (isEn ? 'Present' : 'Hiện tại')
                  : (exp.endDate != null ? '${exp.endDate!.month.toString().padLeft(2, '0')}/${exp.endDate!.year}' : '');
              final period = '$startStr - $endStr';

              buffer.write(
                '<w:p><w:pPr><w:spacing w:before="120" w:after="40"/></w:pPr>'
                '<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="22"/><w:color w:val="0F172A"/></w:rPr>'
                '<w:t>${_escapeXml(exp.company)}</w:t></w:r>'
                '<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:i/><w:sz w:val="19"/><w:color w:val="64748B"/></w:rPr>'
                '<w:t xml:space="preserve">  (${_escapeXml(period)})</w:t></w:r></w:p>',
              );

              final titleLine = exp.location.isNotEmpty
                  ? '${exp.jobTitle} • ${exp.location}'
                  : exp.jobTitle;
              buffer.write(_buildParagraph(titleLine, italic: true, color: '4338CA'));

              for (final bullet in exp.bulletPoints) {
                buffer.write(_buildBullet(bullet));
              }
            }
          }
          break;

        case 'projects':
          if (cv.projects.isNotEmpty) {
            buffer.write(_buildHeading(isEn ? 'KEY PROJECTS' : 'DỰ ÁN NỔI BẬT'));
            for (final proj in cv.projects) {
              buffer.write(
                '<w:p><w:pPr><w:spacing w:before="120" w:after="40"/></w:pPr>'
                '<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="22"/><w:color w:val="0F172A"/></w:rPr>'
                '<w:t>${_escapeXml(proj.name)}</w:t></w:r></w:p>',
              );

              final meta = [
                if (proj.role.isNotEmpty) proj.role,
                if (proj.technologies.isNotEmpty) proj.technologies.join(', '),
              ].join(' | ');
              if (meta.isNotEmpty) {
                buffer.write(_buildParagraph(meta, italic: true, color: '64748B'));
              }

              if (proj.sourceUrl?.isNotEmpty == true) {
                buffer.write(_buildParagraph('GitHub: ${proj.sourceUrl}', color: '2563EB'));
              }
              if (proj.demoUrl?.isNotEmpty == true) {
                buffer.write(_buildParagraph('Live Demo: ${proj.demoUrl}', color: '2563EB'));
              }

              for (final line in proj.description.split('\n')) {
                final trimmed = line.trim();
                if (trimmed.isNotEmpty) {
                  buffer.write(_buildBullet(trimmed));
                }
              }
            }
          }
          break;

        case 'education':
          if (cv.educations.isNotEmpty) {
            buffer.write(_buildHeading(isEn ? 'EDUCATION' : 'HỌC VẤN & BẰNG CẤP'));
            for (final edu in cv.educations) {
              final startYear = edu.startDate.year;
              final endYear = edu.isCurrent
                  ? (isEn ? 'Present' : 'Hiện tại')
                  : (edu.endDate?.year.toString() ?? '');
              final period = '$startYear - $endYear';

              buffer.write(
                '<w:p><w:pPr><w:spacing w:before="100" w:after="40"/></w:pPr>'
                '<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="22"/><w:color w:val="0F172A"/></w:rPr>'
                '<w:t>${_escapeXml(edu.institution)}</w:t></w:r>'
                '<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:i/><w:sz w:val="19"/><w:color w:val="64748B"/></w:rPr>'
                '<w:t xml:space="preserve">  ($period)</w:t></w:r></w:p>',
              );

              final sub = '${edu.degree} — ${edu.fieldOfStudy}${edu.gpa != null ? " (GPA: ${edu.gpa})" : ""}';
              buffer.write(_buildParagraph(sub, color: '334155'));

              for (final ach in edu.achievements) {
                buffer.write(_buildBullet(ach));
              }
            }
          }
          break;

        case 'skills':
          if (cv.skills.isNotEmpty) {
            buffer.write(_buildHeading(isEn ? 'SKILLS' : 'KỸ NĂNG CHUYÊN MÔN'));
            final hardSkills = cv.skills
                .where((s) => s.category.name == 'hard')
                .map((s) => s.name)
                .join(', ');
            final softSkills = cv.skills
                .where((s) => s.category.name == 'soft')
                .map((s) => s.name)
                .join(', ');

            if (hardSkills.isNotEmpty) {
              buffer.write(_buildParagraph('${isEn ? "Technical Skills" : "Kỹ năng chuyên môn"}: $hardSkills'));
            }
            if (softSkills.isNotEmpty) {
              buffer.write(_buildParagraph('${isEn ? "Soft Skills" : "Kỹ năng mềm"}: $softSkills'));
            }
          }
          break;

        case 'certifications':
          if (cv.certifications.isNotEmpty) {
            buffer.write(_buildHeading(isEn ? 'CERTIFICATIONS' : 'CHỨNG CHỈ & GIẢI THƯỞNG'));
            for (final cert in cv.certifications) {
              final text = '${cert.name}${cert.score?.isNotEmpty == true ? " (Score: ${cert.score})" : ""}${cert.issuer.isNotEmpty ? " • ${cert.issuer}" : ""}';
              buffer.write(_buildBullet(text));
            }
          }
          break;
      }
    }

    // End body
    buffer.write(
      '<w:sectPr>'
      '<w:pgSz w:w="11906" w:h="16838"/>' // A4: 210mm x 297mm (11906 x 16838 twips)
      '<w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/>'
      '</w:sectPr>'
      '</w:body></w:document>',
    );

    final documentXml = buffer.toString();

    // Content types
    final contentTypesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '</Types>';

    // Package relationships
    final relsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>';

    // Assemble ZIP archive
    final archive = Archive();
    archive.addFile(ArchiveFile.string('[Content_Types].xml', contentTypesXml));
    archive.addFile(ArchiveFile.string('_rels/.rels', relsXml));
    archive.addFile(ArchiveFile.string('word/document.xml', documentXml));

    final zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes);
  }

  String _buildHeading(String text) {
    return '<w:p><w:pPr><w:spacing w:before="240" w:after="80"/><w:pBdr><w:bottom w:val="single" w:sz="6" w:space="2" w:color="4338CA"/></w:pBdr></w:pPr>'
        '<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="24"/><w:color w:val="4338CA"/></w:rPr>'
        '<w:t>${_escapeXml(text)}</w:t></w:r></w:p>';
  }

  String _buildParagraph(
    String text, {
    bool bold = false,
    bool italic = false,
    String color = '334155',
  }) {
    return '<w:p><w:pPr><w:spacing w:after="60"/></w:pPr>'
        '<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>'
        '${bold ? "<w:b/>" : ""}${italic ? "<w:i/>" : ""}'
        '<w:color w:val="$color"/><w:sz w:val="20"/></w:rPr>'
        '<w:t xml:space="preserve">${_escapeXml(text)}</w:t></w:r></w:p>';
  }

  String _buildBullet(String text) {
    return '<w:p><w:pPr><w:ind w:left="360"/><w:spacing w:after="40"/></w:pPr>'
        '<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:color w:val="1E293B"/><w:sz w:val="19"/></w:rPr>'
        '<w:t xml:space="preserve">• ${_escapeXml(text)}</w:t></w:r></w:p>';
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
