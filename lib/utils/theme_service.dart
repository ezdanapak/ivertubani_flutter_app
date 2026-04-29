import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app theme (light/dark) with SharedPreferences persistence.
///
/// Usage:
///   await ThemeService.instance.init();
///   ThemeService.instance.themeMode  // current mode
///   ThemeService.instance.toggle()   // switch and save
///   ThemeService.instance.notifier   // ValueNotifier to listen to
class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const _key = 'theme_mode';

  final ValueNotifier<ThemeMode> notifier = ValueNotifier(ThemeMode.light);

  ThemeMode get themeMode => notifier.value;

  /// Call once in main() before runApp.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'dark') {
      notifier.value = ThemeMode.dark;
    } else {
      notifier.value = ThemeMode.light; // default: light
    }
  }

  Future<void> toggle() async {
    notifier.value = notifier.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      notifier.value == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  bool get isDark => notifier.value == ThemeMode.dark;
}
