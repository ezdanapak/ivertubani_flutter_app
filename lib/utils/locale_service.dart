import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that persists the user's locale choice across sessions.
///
/// Usage:
///   await LocaleService.instance.init();   // call once in main()
///   LocaleService.instance.toggle();        // switches ka ↔ en
///   LocaleService.instance.notifier         // ValueNotifier<Locale>
class LocaleService {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  static const _key = 'locale';

  // Default: Georgian
  final ValueNotifier<Locale> notifier = ValueNotifier(const Locale('ka'));

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      notifier.value = Locale(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    notifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  Future<void> toggle() async {
    final next = isGeorgian ? const Locale('en') : const Locale('ka');
    await setLocale(next);
  }

  bool get isGeorgian => notifier.value.languageCode == 'ka';
}
