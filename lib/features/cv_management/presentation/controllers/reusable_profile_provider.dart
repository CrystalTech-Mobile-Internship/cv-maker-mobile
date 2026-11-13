import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cv_editor/data/repositories/cv_repository_provider.dart';
import '../../../cv_editor/domain/models/cv_model.dart';

final reusableProfileProvider = StreamProvider.autoDispose<CvModel?>((ref) {
  final user = ref.watch(currentAuthUserProvider);
  return ref.watch(cvRepositoryProvider).watchAll().map((items) {
    final candidates =
        items
            .where((cv) {
              if (user == null) return cv.userId == null;
              return cv.userId == null || cv.userId == user.id;
            })
            .where((cv) {
              final info = cv.personalInfo;
              return info.fullName.isNotEmpty ||
                  info.email.isNotEmpty ||
                  info.phone.isNotEmpty ||
                  cv.skills.isNotEmpty;
            })
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return candidates.firstOrNull;
  });
});
