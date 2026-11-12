import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which user ids signed in on this device and their email. The
/// two Supabase projects issue different user ids for the same person, so
/// this lets the app recognise local CVs created under the other project.
class KnownAccountStore {
  const KnownAccountStore();

  static const _key = 'known_accounts_v1';

  Future<Map<String, String>> _read() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((key, value) => MapEntry('$key', '$value'));
    } catch (_) {
      return {};
    }
  }

  /// Records [userId] → [email] and returns the other user ids that belong
  /// to the same email (case-insensitive).
  Future<Set<String>> rememberAndFindAliases({
    required String userId,
    required String email,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return const {};
    final accounts = await _read();
    accounts[userId] = normalized;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(accounts));
    return {
      for (final entry in accounts.entries)
        if (entry.key != userId && entry.value == normalized) entry.key,
    };
  }
}
