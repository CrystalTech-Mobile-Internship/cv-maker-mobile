import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/supabase_auth_data_source.dart';
import '../../data/guest_session_service.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';

final supabaseAuthDataSourceProvider = Provider<SupabaseAuthDataSource>(
  (ref) => SupabaseAuthDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseAuthDataSourceProvider)),
);

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthActionState>(
      (ref) => AuthController(
        repository: ref.watch(authRepositoryProvider),
        guestSessionService: ref.watch(guestSessionServiceProvider),
      ),
    );

final authSessionChangesProvider = StreamProvider<AuthSessionChange>(
  (ref) => ref.watch(authRepositoryProvider).watchSession(),
);

final currentAuthUserProvider = Provider<AuthUser?>((ref) {
  final change = ref.watch(authSessionChangesProvider).valueOrNull;
  final repositoryUser = ref.watch(authRepositoryProvider).currentUser;
  if (change?.event == AuthSessionEvent.signedOut) return repositoryUser;
  // The latest auth event carries the user before the client cache updates
  // (e.g. right after a password recovery link is opened).
  return change?.user ?? repositoryUser;
});
