import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_providers.dart';
import '../../support/domain/support_models.dart';
import '../data/supabase_admin_repository.dart';
import '../domain/admin_models.dart';

/// True only for accounts listed as admins on the server.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(currentAuthUserProvider.select((user) => user?.id));
  if (userId == null) return false;
  return ref.watch(adminRepositoryProvider).isAdmin();
});

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>(
  (ref) => ref.watch(adminRepositoryProvider).stats(),
);

/// Inbox list, refreshed whenever a support message arrives.
final adminThreadsProvider = StreamProvider.autoDispose<List<SupportThread>>((
  ref,
) async* {
  final repository = ref.watch(adminRepositoryProvider);
  yield await repository.threads();
  await for (final _ in repository.supportChanges()) {
    yield await repository.threads();
  }
});

final adminConversationProvider = StreamProvider.autoDispose
    .family<List<SupportMessage>, String>(
      (ref, userId) => ref.watch(adminRepositoryProvider).conversation(userId),
    );

final adminProRequestsProvider =
    FutureProvider.autoDispose<List<AdminProRequest>>(
      (ref) => ref.watch(adminRepositoryProvider).proRequests(),
    );

final adminPaymentEventsProvider =
    FutureProvider.autoDispose<List<AdminPaymentEvent>>(
      (ref) => ref.watch(adminRepositoryProvider).paymentEvents(),
    );
