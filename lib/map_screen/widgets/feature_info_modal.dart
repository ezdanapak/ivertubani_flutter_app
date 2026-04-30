import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ivertubani/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/analytics_service.dart';

class FeatureInfoModal extends StatefulWidget {
  const FeatureInfoModal({super.key, required this.displayData});

  final List<MapEntry<String, dynamic>> displayData;

  static void openFutureInfoModal(
    BuildContext context, {
    required Map<String, dynamic> attributes,
  }) {
    final technicalFields = [
      'fid', 'geom', 'geometry', 'lat', 'long', 'lon', 'id', 'ogc_fid',
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
      useSafeArea: true,
      // Web / tablet-ზე showModalBottomSheet ეკრანის შუაში პატარად გამოჩნდება.
      // maxWidth: double.infinity — აიძულებს full-width-ს ნებისმიერ ეკრანზე.
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => FeatureInfoModal(displayData: displayData),
    );
  }

  @override
  State<FeatureInfoModal> createState() => _FeatureInfoModalState();
}

class _FeatureInfoModalState extends State<FeatureInfoModal> {
  // Key of the field that was just copied — null when no active feedback.
  String? _copiedKey;
  Timer? _clearTimer;

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  void _onLinkPress(String urlString) async {
    final poiName = widget.displayData
        .firstWhere(
          (e) => e.key.toLowerCase() == 'name',
          orElse: () => const MapEntry('', ''),
        )
        .value
        .toString();
    AnalyticsService.instance.logGoogleMapsOpened(poiName: poiName);

    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _onTextPress(String fieldKey, String text) {
    Clipboard.setData(ClipboardData(text: text));

    // Show ✓ next to the tapped field for 1.5 s, then reset.
    setState(() => _copiedKey = fieldKey);
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copiedKey = null);
    });
  }

  Widget _buildLinkButton(String text, VoidCallback onPress) {
    return GestureDetector(
      onTap: onPress,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildCopyButton(
    String fieldKey,
    String text,
    ColorScheme scheme,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final isCopied = _copiedKey == fieldKey;

    return GestureDetector(
      onTap: isCopied ? null : () => _onTextPress(fieldKey, text),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isCopied
            ? Row(
                key: const ValueKey('copied'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 15, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    l10n.copiedLabel,
                    key: const ValueKey('copied_text'),
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                key: ValueKey('$fieldKey:$text'),
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          // drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 25),
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          ...widget.displayData.map((e) {
            final valString = e.value.toString().trim();
            final isLink =
                valString.startsWith('http') ||
                e.key.toLowerCase().contains('google map');

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Label: ფიქსირებული სიგანე, მხოლოდ საჭირო სივრცე ──
                  SizedBox(
                    width: 90,
                    child: Text(
                      e.key.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── Value: დარჩენილი სივრცე მთლიანად ──
                  Expanded(
                    child: isLink
                        ? _buildLinkButton(
                            l10n.viewOnGoogleMaps,
                            () => _onLinkPress(valString),
                          )
                        : _buildCopyButton(
                            e.key,
                            valString,
                            scheme,
                            l10n,
                            isDark,
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
