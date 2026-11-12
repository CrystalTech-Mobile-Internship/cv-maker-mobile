import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that the user accepted sending CV content to the AI service.
class AiConsentService {
  const AiConsentService();

  static const _key = 'ai_data_consent_v1';

  Future<bool> hasConsented() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_key) ?? false;
  }

  Future<void> recordConsent() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, true);
  }
}
