import 'dart:typed_data';

import 'package:cv_maker_mobile/features/cv_backup/data/repositories/json_cv_backup_repository.dart';
import 'package:cv_maker_mobile/features/cv_backup/domain/repositories/cv_backup_repository.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/cv_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repository = JsonCvBackupRepository();

  test('round-trips all CV data through a versioned JSON backup', () {
    final cv = CvModel.empty(
      id: 'cv-1',
      language: 'vi',
      now: DateTime.utc(2026, 10, 30),
    ).copyWith(title: 'Flutter Developer');

    final bytes = repository.encodeBackup([
      cv,
    ], exportedAt: DateTime.utc(2026, 10, 30));
    final restored = repository.decodeBackup(bytes);

    expect(restored, hasLength(1));
    expect(restored.single.toJson(), cv.toJson());
  });

  test('rejects an unrelated or corrupted JSON file', () {
    expect(
      () => repository.decodeBackup(
        Uint8List.fromList('{"app":"Other","cvs":[]}'.codeUnits),
      ),
      throwsA(isA<CvBackupException>()),
    );
    expect(
      () => repository.decodeBackup(Uint8List.fromList('not-json'.codeUnits)),
      throwsA(isA<CvBackupException>()),
    );
  });
}
