class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.provider,
    required this.isEmailConfirmed,
  });

  final String id;
  final String email;
  final String displayName;
  final String provider;
  final bool isEmailConfirmed;
}

enum AuthSessionEvent {
  initial,
  signedIn,
  signedOut,
  passwordRecovery,
  tokenRefreshed,
  userUpdated,
  other,
}

class AuthSessionChange {
  const AuthSessionChange({required this.event, required this.user});

  final AuthSessionEvent event;
  final AuthUser? user;
}
