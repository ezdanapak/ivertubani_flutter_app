import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/marker_style.dart';

class IvertubaniDrawer extends StatelessWidget {
  const IvertubaniDrawer({
    super.key,
    required this.enabledCategories,
    required this.onCategoryPress,
  });

  final Set<MapCategory> enabledCategories;

  final ValueChanged<({bool? selected, MapCategory category})> onCategoryPress;

  void _onButtonPress() async {
    final Uri url = Uri.parse(
      'https://github.com/ezdanapak/ivertubani_flutter_app',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double systemBottom = MediaQuery.of(
      context,
    ).systemGestureInsets.bottom;

    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo),
            child: Center(
              child: Text(
                'მენიუ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: systemBottom + 20),
              children: [
                ExpansionTile(
                  leading: const Icon(Icons.filter_list, color: Colors.indigo),
                  title: const Text('შრეების მართვა'),
                  initiallyExpanded: true,

                  children: MapCategory.values.map((category) {
                    return CheckboxListTile(
                      title: Text(category.label),
                      value: enabledCategories.contains(category),
                      onChanged: (selected) {
                        onCategoryPress((
                          selected: selected,
                          category: category,
                        ));
                      },
                    );
                  }).toList(),
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.indigo),
                  title: const Text('აპლიკაციის შესახებ'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ივერთუბნის რუკა v1.0\nგანახლებულია: 22.04.2026',
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _onButtonPress,
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
