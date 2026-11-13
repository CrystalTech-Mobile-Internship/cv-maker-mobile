import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../../cv_editor/domain/models/cv_model.dart';
import '../../domain/repositories/cv_backup_repository.dart';

final class JsonCvBackupRepository implements CvBackupRepository {
  static const int formatVersion = 1;
  static const int maxBytes = 8 * 1024 * 1024;

  @override
  Future<Uri?> exportBackup(List<CvModel> cvs) {
    final now = DateTime.now().toUtc();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    return FilePicker.saveFile(
      fileName: 'smart-cv-backup-$stamp.json',
      bytes: encodeBackup(cvs, exportedAt: now),
      mimeType: 'application/json',
      dialogTitle: 'Lưu bản sao Smart CV Maker',
    );
  }

  @override
  Future<List<CvModel>?> importBackup() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Chọn bản sao Smart CV Maker',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    final length = file.lengthSync() ?? await file.length() ?? 0;
    if (length > maxBytes) {
      throw const CvBackupException('Tệp sao lưu vượt quá giới hạn 8 MB.');
    }
    return decodeBackup(await file.readAsBytes());
  }

  Uint8List encodeBackup(List<CvModel> cvs, {required DateTime exportedAt}) {
    final payload = <String, Object>{
      'app': 'Smart CV Maker',
      'version': formatVersion,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'cvs': cvs.map((cv) => cv.toJson()).toList(growable: false),
    };
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
  }

  List<CvModel> decodeBackup(Uint8List bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic> ||
          decoded['app'] != 'Smart CV Maker' ||
          decoded['version'] != formatVersion ||
          decoded['cvs'] is! List<dynamic>) {
        throw const CvBackupException(
          'Tệp không đúng định dạng sao lưu Smart CV Maker.',
        );
      }
      final cvs = (decoded['cvs'] as List<dynamic>)
          .map(
            (item) => CvModel.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList(growable: false);
      if (cvs.isEmpty) {
        throw const CvBackupException('Tệp sao lưu không chứa CV nào.');
      }
      return cvs;
    } on CvBackupException {
      rethrow;
    } catch (_) {
      throw const CvBackupException(
        'Tệp sao lưu bị hỏng hoặc không thể đọc được.',
      );
    }
  }
}
