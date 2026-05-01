import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ivertubani/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/analytics_service.dart';

class FeatureInfoModal extends StatefulWidget {
  const FeatureInfoModal({
    super.key,
    required this.displayData,
    this.lat,
    this.lon,
  });

  final List<MapEntry<String, dynamic>> displayData;

  /// WGS84 coordinates — null if not available (used for share).
  final double? lat;
  final double? lon;

  static void openFutureInfoModal(
    BuildContext context, {
    required Map<String, dynamic> attributes,
  }) {
    const technicalFields = {
      'fid', 'geom', 'geometry', 'lat', 'long', 'lon', 'id', 'ogc_fid',
    };

    // Extract coordinates before filtering them out
    final lat = double.tryParse(attributes['lat']?.toString() ?? '');
    final lon = double.tryParse(
      (attributes['long'] ?? attributes['lon'])?.toString() ?? '',
    );

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
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => FeatureInfoModal(
        displayData: displayData,
        lat: lat,
        lon: lon,
      ),
    );
  }

  @override
  State<FeatureInfoModal> createState() => _FeatureInfoModalState();
}

class _FeatureInfoModalState extends State<FeatureInfoModal> {
  String? _copiedKey;
  Timer?  _clearTimer;

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────────

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
    setState(() => _copiedKey = fieldKey);
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copiedKey = null);
    });
  }

  void _onSharePoi() {
    if (widget.lat == null || widget.lon == null) return;

    final name = widget.displayData
        .firstWhere(
          (e) => e.key.toLowerCase() == 'name',
          orElse: () => const MapEntry('', ''),
        )
        .value
        .toString();

    final desc = widget.displayData
        .firstWhere(
          (e) => e.key.toLowerCase() == 'description',
          orElse: () => const MapEntry('', ''),
        )
        .value
        .toString();

    final lat = widget.lat!.toStringAsFixed(6);
    final lon = widget.lon!.toStringAsFixed(6);

    final buffer = StringBuffer();
    if (name.isNotEmpty) buffer.writeln('📍 $name');
    if (desc.isNotEmpty) buffer.writeln(desc);
    buffer.writeln('🌍 WGS84: $lat° N, $lon° E');
    buffer.write('https://maps.google.com/?q=${widget.lat},${widget.lon}');

    Share.share(buffer.toString(), subject: name.isNotEmpty ? name : 'ივერთუბანი');
  }

  // ─── Builders ─────────────────────────────────────────────────────────────────

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
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.centerLeft,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: isCopied
            ? Row(
                key: const ValueKey('copied'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 15, color: scheme.primary),
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
    final l10n   = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,   // ← forces full bottom-sheet width
      padding: EdgeInsets.only(
        left:   20,
        right:  20,
        top:    10,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── drag handle ──────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // ── Fields ───────────────────────────────────────────────────────────
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
                  Expanded(
                    child: isLink
                        ? _buildLinkButton(
                            l10n.viewOnGoogleMaps,
                            () => _onLinkPress(valString),
                          )
                        : _buildCopyButton(e.key, valString, scheme, l10n, isDark),
                  ),
                ],
              ),
            );
          }),

          // ── Share button (only when coordinates are available) ────────────────
          if (widget.lat != null && widget.lon != null) ...[
            const SizedBox(height: 4),
            const Divider(),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _onSharePoi,
                icon: const Icon(Icons.share, size: 14),
                label: const Text('გაზიარება', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
