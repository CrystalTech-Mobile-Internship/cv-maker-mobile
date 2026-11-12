import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cv_editor/data/repositories/cv_repository_provider.dart';
import '../../../cv_editor/domain/models/cv_model.dart';

/// Local CVs visible to the current session: Guest CVs plus the CVs owned by
/// the signed-in account.
final cvListStreamProvider = StreamProvider.autoDispose<List<CvModel>>((ref) {
  final repository = ref.watch(cvRepositoryProvider);
  final user = ref.watch(currentAuthUserProvider);
  return repository.watchAll().map((cvs) {
    if (user == null) {
      return cvs.where((cv) => cv.userId == null).toList(growable: false);
    }
    return cvs
        .where((cv) => cv.userId == null || cv.userId == user.id)
        .toList(growable: false);
  });
});
