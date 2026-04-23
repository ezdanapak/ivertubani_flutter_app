import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class FeatureInfoModal extends StatelessWidget {
  const FeatureInfoModal({super.key, required this.displayData});

  final List<MapEntry<String, dynamic>> displayData;

  static void openFutureInfoModal(
    BuildContext context, {
    required Map<String, dynamic> attributes,
  }) {
    final technicalFields = [
      'fid',
      'geom',
      'geometry',
      'lat',
      'long',
      'lon',
      'id',
      'ogc_fid',
    ];
    final displayData = attributes.entries.where((e) {
      final key = e.key.toLowerCase();
      final val = e.value?.toString().trim() ?? '';
      return !technicalFields.contains(key) &&
          val.isNotEmpty &&
          e.value is! Uint8List;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => FeatureInfoModal(displayData: displayData),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPress,
    bool isLink = false,
  }) {
    return GestureDetector(
      onTap: onPress,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: Colors.blue,
          fontWeight: isLink ? FontWeight.bold : null,
          decoration: isLink ? TextDecoration.underline : null,
        ),
      ),
    );
  }

  void _onLinkPress(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _onTextPress(BuildContext context, String text) async {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('დაკოპირდა: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 25),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          ...displayData.map((e) {
            final valString = e.value.toString().trim();
            final isLink =
                valString.startsWith('http') ||
                e.key.toLowerCase().contains('google map');

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      e.key.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: isLink
                        ? _buildButton(
                            onPress: () => _onLinkPress(valString),
                            text: 'იხილეთ Google Maps-ზე ➔',
                            isLink: true,
                          )
                        : _buildButton(
                            onPress: () => _onTextPress(context, valString),
                            text: valString,
                            isLink: false,
                          ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
