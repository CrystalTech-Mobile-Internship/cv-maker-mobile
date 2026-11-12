import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/known_account_store.dart';
import '../../domain/repositories/cv_repository.dart';
import '../repositories/cv_repository_provider.dart';

/// After sign-in, re-assigns local CVs owned by another user id with the same
/// email (from the other Supabase project) to the current account so they
/// stay visible and are synchronised to the active project. Guest CVs are
/// never touched.
class LinkedAccountCvAdopter {
  LinkedAccountCvAdopter(this._repository, {KnownAccountStore? store})
    : _store = store ?? const KnownAccountStore();

  final CvRepository _repository;
  final KnownAccountStore _store;

  /// Returns how many CVs were adopted.
  Future<int> adopt({required String userId, required String email}) async {
    final aliases = await _store.rememberAndFindAliases(
      userId: userId,
      email: email,
    );
    if (aliases.isEmpty) return 0;
    final cvs = await _repository.getAll();
    var adopted = 0;
    for (final cv in cvs) {
      final owner = cv.userId;
      if (owner == null || !aliases.contains(owner)) continue;
      await _repository.save(cv.copyWith(userId: userId), now: cv.updatedAt);
      adopted++;
    }
    return adopted;
  }
}

final linkedAccountCvAdopterProvider = Provider<LinkedAccountCvAdopter>(
  (ref) => LinkedAccountCvAdopter(ref.watch(cvRepositoryProvider)),
);
