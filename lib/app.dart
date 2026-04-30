import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:ivertubani/generated/app_localizations.dart';
import 'map_screen/screen/map_screen.dart';
import 'utils/locale_service.dart';
import 'utils/theme_service.dart';

// Fallback seed — გამოიყენება iOS-ზე და Android 11-ზე ან უფრო ძველზე,
// სადაც dynamic color მხარდაჭერილი არ არის.
const _seedColor = Colors.indigo;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // AppBar-ის ფერი colorScheme.primary-ზე დაყრდნობით —
  // dynamic color-ის შემთხვევაში მომხმარებლის სისტემის ფერი გამოიყენება.
  static AppBarTheme _appBarTheme(ColorScheme scheme) => AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      );

  static ThemeData _buildTheme(ColorScheme scheme) => ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        appBarTheme: _appBarTheme(scheme),
      );

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Android 12+ — სისტემის wallpaper-ის ფერი
        // iOS / Android 11- — indigo seed-ზე დაყრდნობილი scheme
        final lightScheme = lightDynamic ??
            ColorScheme.fromSeed(
              seedColor: _seedColor,
              brightness: Brightness.light,
            );
        final darkScheme = darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: _seedColor,
              brightness: Brightness.dark,
            );

        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.instance.notifier,
          builder: (_, themeMode, __) {
            return ValueListenableBuilder<Locale>(
              valueListenable: LocaleService.instance.notifier,
              builder: (_, locale, __) {
                return MaterialApp(
                  onGenerateTitle: (ctx) =>
                      AppLocalizations.of(ctx).appTitle,
                  debugShowCheckedModeBanner: false,
                  theme: _buildTheme(lightScheme),
                  darkTheme: _buildTheme(darkScheme),
                  themeMode: themeMode,
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: const MapScreen(),
                );
              },
            );
          },
        );
      },
    );
  }
}
