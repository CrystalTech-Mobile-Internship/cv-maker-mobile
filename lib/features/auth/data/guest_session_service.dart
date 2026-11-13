import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

final guestSessionServiceProvider = Provider<GuestSessionService>(
  (ref) => const GuestSessionService(),
);

/// Persists only the user's choice to work as an offline guest.
///
/// CV content remains in Drift SQLite; no personal CV data is placed in
/// preferences. Keeping this flag lets guests reopen their local workspace
/// without being forced through an online sign-in screen.
final class GuestSessionService {
  const GuestSessionService();

  Future<bool> isGuestMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(AppConstants.prefIsGuestMode) ?? false;
  }

  Future<void> setGuestMode(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(AppConstants.prefIsGuestMode, value);
  }
}
