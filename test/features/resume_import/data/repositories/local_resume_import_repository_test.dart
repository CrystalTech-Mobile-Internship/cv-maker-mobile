import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cv_maker_mobile/features/resume_import/data/repositories/local_resume_import_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads DOCX document XML fully offline', () async {
    const documentXml = '''
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:body>
          <w:p><w:r><w:t>TRẦN VĂN HÒA</w:t></w:r></w:p>
          <w:p><w:r><w:t>Flutter Developer</w:t></w:r></w:p>
          <w:p><w:r><w:t>hoa@example.com</w:t></w:r></w:p>
          <w:p><w:r><w:t>KỸ NĂNG</w:t></w:r></w:p>
          <w:p><w:r><w:t>Flutter, Dart, Supabase</w:t></w:r></w:p>
        </w:body>
      </w:document>
    ''';
    final xmlBytes = Uint8List.fromList(utf8.encode(documentXml.trim()));
    final archive = Archive()
      ..addFile(ArchiveFile('word/document.xml', xmlBytes.length, xmlBytes));
    final docx = Uint8List.fromList(ZipEncoder().encode(archive));

    final draft = await LocalResumeImportRepository().parseBytes(
      fileName: 'hoa.docx',
      bytes: docx,
    );

    expect(draft.fullName, 'TRẦN VĂN HÒA');
    expect(draft.email, 'hoa@example.com');
    expect(draft.skills, containsAll(['Flutter', 'Dart', 'Supabase']));
  });
}
