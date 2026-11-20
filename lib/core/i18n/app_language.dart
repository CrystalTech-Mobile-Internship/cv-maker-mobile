import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages the app interface can be shown in.
enum AppLanguage {
  vi('vi', 'Tiếng Việt'),
  en('en', 'English');

  const AppLanguage(this.code, this.nativeName);

  final String code;

  /// Name written in the language itself, so anyone can find their own.
  final String nativeName;

  static AppLanguage fromCode(String? code) =>
      code == 'en' ? AppLanguage.en : AppLanguage.vi;
}

/// Current interface language, readable outside the widget tree (error
/// messages in repositories, domain hints). Widgets rebuild through
/// [appLanguageProvider]; the app re-keys its tree when it changes.
abstract final class AppI18n {
  static AppLanguage current = AppLanguage.vi;

  static const _prefsKey = 'app_language';

  /// Loads the saved choice, or follows the device language on first run.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      current = saved != null
          ? AppLanguage.fromCode(saved)
          : (PlatformDispatcher.instance.locale.languageCode == 'vi'
                ? AppLanguage.vi
                : AppLanguage.en);
    } catch (_) {
      // Storage can be blocked (private browsing): keep the default.
    }
  }

  static Future<void> save(AppLanguage language) async {
    current = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, language.code);
    } catch (_) {
      // The choice still applies for this session.
    }
  }
}

/// Picks the text for the current interface language.
String tr(String vi, String en) => AppI18n.current == AppLanguage.en ? en : vi;

/// Whether the interface is in English.
bool get appInEnglish => AppI18n.current == AppLanguage.en;

class AppLanguageController extends StateNotifier<AppLanguage> {
  AppLanguageController() : super(AppI18n.current);

  Future<void> change(AppLanguage language) async {
    if (language == state) return;
    await AppI18n.save(language);
    state = language;
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageController, AppLanguage>(
      (ref) => AppLanguageController(),
    );
