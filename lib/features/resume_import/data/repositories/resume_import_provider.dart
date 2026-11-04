import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/resume_import_repository.dart';
import 'local_resume_import_repository.dart';

final resumeImportRepositoryProvider = Provider<ResumeImportRepository>((ref) {
  return LocalResumeImportRepository();
});
