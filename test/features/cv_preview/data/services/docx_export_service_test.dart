import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_preview/data/services/docx_export_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocxExportServiceImpl', () {
    test('generates valid DOCX ZIP package with OpenXML structure', () async {
      const service = DocxExportServiceImpl();
      final cv = CvModel.empty(id: 'docx-test').copyWith(
        personalInfo: const PersonalInfoModel(
          fullName: 'Nguyễn Tuấn Anh',
          targetRole: 'Mobile Developer',
          email: 'tuananh@example.com',
          phone: '0901234567',
        ),
        summary: 'Kỹ sư phần mềm đam mê công nghệ & Clean Architecture <test>.',
        skills: const [
          SkillModel(id: 's1', name: 'Flutter & Dart', category: SkillCategory.hard),
        ],
        experiences: [
          ExperienceModel(
            id: 'e1',
            company: 'Công ty Alpha',
            jobTitle: 'Flutter Dev',
            startDate: DateTime.utc(2025, 1, 1),
            bulletPoints: const ['Phát triển ứng dụng di động & tối ưu SQLite'],
          ),
        ],
      );

      final bytes = await service.generateDocx(cv: cv, language: 'vi');
      expect(bytes, isNotEmpty);

      // Verify ZIP magic bytes (PK\x03\x04)
      expect(bytes[0], 0x50); // 'P'
      expect(bytes[1], 0x4B); // 'K'
      expect(bytes[2], 0x03);
      expect(bytes[3], 0x04);

      // Verify Archive contents
      final archive = ZipDecoder().decodeBytes(bytes);
      final fileNames = archive.files.map((f) => f.name).toList();
      expect(fileNames, contains('[Content_Types].xml'));
      expect(fileNames, contains('_rels/.rels'));
      expect(fileNames, contains('word/document.xml'));

      // Verify XML content in word/document.xml
      final docXmlFile = archive.findFile('word/document.xml');
      expect(docXmlFile, isNotNull);
      final xmlString = utf8.decode(docXmlFile!.content as List<int>);

      expect(xmlString, contains('NGUYỄN TUẤN ANH'));
      expect(xmlString, contains('MOBILE DEVELOPER'));
      expect(xmlString, contains('MỤC TIÊU NGHỀ NGHIỆP'));
      // Verify XML escaping of '<' and '&'
      expect(xmlString, contains('&amp;'));
      expect(xmlString, contains('&lt;test&gt;'));
      expect(xmlString, contains('Công ty Alpha'));
      expect(xmlString, contains('Flutter &amp; Dart'));
    });

    test('generates English DOCX package with custom sectionOrder', () async {
      const service = DocxExportServiceImpl();
      final cv = CvModel.empty(id: 'docx-en').copyWith(
        language: 'en',
        sectionOrder: ['skills', 'summary', 'experience', 'projects', 'education', 'certifications'],
        personalInfo: const PersonalInfoModel(
          fullName: 'Tuan Anh Nguyen',
          targetRole: 'Software Engineer',
        ),
        summary: 'Experienced software engineer.',
        skills: const [
          SkillModel(id: 's1', name: 'Flutter', category: SkillCategory.hard),
        ],
      );

      final bytes = await service.generateDocx(cv: cv, language: 'en');
      final archive = ZipDecoder().decodeBytes(bytes);
      final xmlString = utf8.decode(archive.findFile('word/document.xml')!.content as List<int>);

      expect(xmlString, contains('TUAN ANH NGUYEN'));
      expect(xmlString, contains('SOFTWARE ENGINEER'));
      expect(xmlString, contains('SKILLS'));
      expect(xmlString, contains('PROFESSIONAL SUMMARY'));

      // Skills heading must appear before Summary heading because of sectionOrder
      final skillsIndex = xmlString.indexOf('SKILLS');
      final summaryIndex = xmlString.indexOf('PROFESSIONAL SUMMARY');
      expect(skillsIndex, lessThan(summaryIndex));
    });
  });
}
