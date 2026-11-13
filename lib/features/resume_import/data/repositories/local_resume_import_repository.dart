import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:xml/xml.dart';

import '../../domain/models/resume_import_draft.dart';
import '../../domain/repositories/resume_import_repository.dart';
import '../services/resume_text_parser.dart';

final class LocalResumeImportRepository implements ResumeImportRepository {
  LocalResumeImportRepository({
    ResumeTextParser parser = const ResumeTextParser(),
  }) : _parser = parser;

  static const _maxFileBytes = 8 * 1024 * 1024;
  final ResumeTextParser _parser;

  @override
  Future<ResumeImportDraft?> pickAndParse() async {
    final source = await pickAndExtractText();
    return source == null ? null : parseText(source);
  }

  @override
  ResumeImportDraft parseText(ResumeTextSource source) =>
      _parser.parse(sourceName: source.fileName, text: source.text);

  @override
  Future<ResumeTextSource?> pickAndExtractText() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Chọn CV Word hoặc PDF',
      type: FileType.custom,
      allowedExtensions: const ['docx', 'pdf'],
    );
    if (file == null) return null;

    final length = file.lengthSync() ?? await file.length() ?? 0;
    if (length > _maxFileBytes) {
      throw const ResumeImportException('Tệp CV phải nhỏ hơn 8 MB.');
    }
    final text = await extractText(
      fileName: file.name,
      bytes: await file.readAsBytes(),
    );
    return ResumeTextSource(fileName: file.name, text: text);
  }

  @override
  Future<ResumeImportDraft> parseBytes({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final text = await extractText(fileName: fileName, bytes: bytes);
    return _parser.parse(sourceName: fileName, text: text);
  }

  Future<String> extractText({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (bytes.length > _maxFileBytes) {
      throw const ResumeImportException('Tệp CV phải nhỏ hơn 8 MB.');
    }
    final extension = fileName.split('.').last.toLowerCase();
    final text = switch (extension) {
      'docx' => _extractDocx(bytes),
      'pdf' => await _extractPdf(bytes, fileName),
      _ => throw const ResumeImportException('Chỉ hỗ trợ tệp .docx và .pdf.'),
    };
    if (text.trim().isEmpty) {
      throw const ResumeImportException(
        'Không tìm thấy lớp chữ. CV scan/ảnh cần OCR và chưa được hỗ trợ.',
      );
    }
    return text;
  }

  String _extractDocx(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final document = archive.files.firstWhere(
        (entry) => entry.name == 'word/document.xml',
      );
      final xml = XmlDocument.parse(utf8.decode(document.content));
      return xml.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 'p')
          .map(
            (paragraph) => paragraph.descendants
                .whereType<XmlElement>()
                .where((element) => element.name.local == 't')
                .map((node) => node.innerText)
                .join(),
          )
          .where((line) => line.trim().isNotEmpty)
          .join('\n');
    } catch (_) {
      throw const ResumeImportException(
        'Không đọc được tệp Word. Hãy lưu lại dưới định dạng .docx.',
      );
    }
  }

  Future<String> _extractPdf(Uint8List bytes, String sourceName) async {
    PdfDocument? document;
    try {
      await pdfrxFlutterInitialize();
      document = await PdfDocument.openData(bytes, sourceName: sourceName);
      await document.loadPagesProgressively();
      final output = StringBuffer();
      for (final page in document.pages) {
        final text = await page.loadText();
        if (text != null) output.writeln(text.fullText);
      }
      return output.toString();
    } catch (_) {
      throw const ResumeImportException(
        'Không đọc được PDF. Tệp có thể bị khóa hoặc chỉ chứa ảnh scan.',
      );
    } finally {
      await document?.dispose();
    }
  }
}
