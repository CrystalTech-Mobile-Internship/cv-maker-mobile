import 'dart:typed_data';

import '../../../cv_editor/domain/models/cv_model.dart';

abstract class DocumentExportRepository {
  Future<Uint8List> generateDocx({
    required CvModel cv,
    required String language,
  });
}
