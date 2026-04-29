import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.indigo.shade200 : Colors.indigo;

    return Drawer(
      child: Column(
        children: [
          // ─── Header ─────────────────────────────────────────────
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDark ? Colors.indigo.shade900 : Colors.indigo,
            ),
            child: const Center(
              child: Text(
                'ივერთუბანი',
                style: TextStyle(
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
                // ─── Dark mode toggle ──────────────────────────────
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
                        mode == ThemeMode.dark ? 'მუქი რეჟიმი' : 'ღია რეჟიმი',
                      ),
                      value: mode == ThemeMode.dark,
                      activeColor: Colors.indigo,
                      onChanged: (_) => ThemeService.instance.toggle(),
                    );
                  },
                ),

                const Divider(),

                // ─── Category filters ──────────────────────────────
                ExpansionTile(
                  leading: Icon(Icons.filter_list, color: iconColor),
                  title: const Text('შრეების მართვა'),
                  initiallyExpanded: true,
                  children: MapCategory.values.map((category) {
                    return CheckboxListTile(
                      title: Text(category.label),
                      value: enabledCategories.contains(category),
                      activeColor: Colors.indigo,
                      onChanged: (selected) {
                        onCategoryPress((
                          selected: selected,
                          category: category,
                        ));
                        // Close drawer after selection
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),

                const Divider(),

                // ─── About ────────────────────────────────────────
                ListTile(
                  leading: Icon(Icons.info_outline, color: iconColor),
                  title: const Text('აპლიკაციის შესახებ'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ივერთუბნის რუკა v1.0\nგანახლებულია: 22.04.2026'),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _onGitHubPress,
                        child: const Text(
                          'ავტორი: ezdanapak ➔',
                          style: TextStyle(
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
