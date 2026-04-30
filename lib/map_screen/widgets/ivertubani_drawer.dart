import 'package:flutter/material.dart';
import 'package:ivertubani/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/analytics_service.dart';
import '../../utils/locale_service.dart';
import '../../utils/marker_style.dart';
import '../../utils/theme_service.dart';

class IvertubaniDrawer extends StatelessWidget {
  const IvertubaniDrawer({
    super.key,
    required this.enabledCategories,
    required this.onCategoryPress,
  });

  final Set<MapCategory> enabledCategories;
  final ValueChanged<({bool? selected, MapCategory category})> onCategoryPress;

  void _onGitHubPress() async {
    final uri = Uri.parse('https://github.com/ezdanapak/ivertubani_flutter_app');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final systemBottom = MediaQuery.of(context).systemGestureInsets.bottom;
    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.primary;
    final l10n = AppLocalizations.of(context);

    return Drawer(
      child: Column(
        children: [
          // ─── Header ───────────────────────────────────────────────
          DrawerHeader(
            decoration: BoxDecoration(color: scheme.primary),
            child: Center(
              child: Text(
                l10n.drawerHeader,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: systemBottom + 20),
              children: [
                // ─── Dark mode toggle ────────────────────────────────
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeService.instance.notifier,
                  builder: (_, mode, __) {
                    return SwitchListTile(
                      secondary: Icon(
                        mode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: iconColor,
                      ),
                      title: Text(
                        mode == ThemeMode.dark
                            ? l10n.darkMode
                            : l10n.lightMode,
                      ),
                      value: mode == ThemeMode.dark,
                      activeColor: scheme.primary,
                      onChanged: (_) {
                        AnalyticsService.instance.logThemeChanged(
                          isDark: mode != ThemeMode.dark,
                        );
                        ThemeService.instance.toggle();
                      },
                    );
                  },
                ),

                // ─── Language switcher ────────────────────────────────
                ValueListenableBuilder<Locale>(
                  valueListenable: LocaleService.instance.notifier,
                  builder: (_, locale, __) {
                    final isGeo = locale.languageCode == 'ka';
                    return ListTile(
                      leading: Icon(Icons.language, color: iconColor),
                      title: Text(l10n.language),
                      subtitle: Text(
                        isGeo ? l10n.languageGeorgian : l10n.languageEnglish,
                      ),
                      trailing: const Icon(Icons.swap_horiz),
                      onTap: () {
                        final next = isGeo ? 'en' : 'ka';
                        AnalyticsService.instance.logLanguageChanged(
                          locale: next,
                        );
                        LocaleService.instance.toggle();
                      },
                    );
                  },
                ),

                const Divider(),

                // ─── Category filters ────────────────────────────────
                // Navigator.pop() CheckboxListTile.onChanged-ში არ არის!
                // მომხმარებელი ერთდროულად რამდენიმე კატეგორიას ირთავს,
                // ამიტომ drawer ხელით უნდა დაიხუროს (ქვემოთ ღილაკი).
                ExpansionTile(
                  leading: Icon(Icons.filter_list, color: iconColor),
                  title: Text(l10n.layerManagement),
                  initiallyExpanded: true,
                  children: MapCategory.values.map((category) {
                    return CheckboxListTile(
                      title: Text(category.labelFor(l10n)),
                      value: enabledCategories.contains(category),
                      activeColor: scheme.primary,
                      onChanged: (selected) => onCategoryPress((
                        selected: selected,
                        category: category,
                      )),
                    );
                  }).toList(),
                ),

                // ─── Close drawer button ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check),
                    label: Text(l10n.closeDrawer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: iconColor,
                      side: BorderSide(color: iconColor),
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),

                const Divider(),

                // ─── About ──────────────────────────────────────────
                ListTile(
                  leading: Icon(Icons.info_outline, color: iconColor),
                  title: Text(l10n.aboutApp),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.aboutText),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _onGitHubPress,
                        child: Text(
                          l10n.author,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
