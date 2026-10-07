import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../domain/repositories/cv_repository.dart';
import 'local_cv_repository.dart';

final cvRepositoryProvider = Provider<CvRepository>((ref) {
  return LocalCvRepository(ref.watch(appDatabaseProvider));
});
