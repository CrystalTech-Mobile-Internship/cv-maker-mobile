/// Result of checking whether this device still owns the account's session
/// for its kind of device (one browser and one phone at a time).
enum DeviceSessionStatus {
  /// This device is the active one.
  current,

  /// The account signed in on another device of the same kind.
  replaced,

  /// Could not tell (offline, server error). Callers must not sign out.
  unknown,
}

abstract interface class DeviceSessionRepository {
  /// Makes this device the active one for its kind (after a fresh sign-in).
  Future<void> claim();

  /// Checks a restored session; claims it when nothing is recorded yet.
  Future<DeviceSessionStatus> check();

  /// Emits when another device of the same kind takes over the account.
  Stream<void> watchReplaced(String userId);
}
