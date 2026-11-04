import '../../../cv_editor/domain/models/cv_model.dart';

abstract interface class CvBackupRepository {
  Future<Uri?> exportBackup(List<CvModel> cvs);

  Future<List<CvModel>?> importBackup();
}

final class CvBackupException implements Exception {
  const CvBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
