import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/cv_backup_repository.dart';
import 'json_cv_backup_repository.dart';

final cvBackupRepositoryProvider = Provider<CvBackupRepository>(
  (ref) => JsonCvBackupRepository(),
);
