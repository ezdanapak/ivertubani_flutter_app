import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../utils/measurement_service.dart';
import '../../utils/utm_service.dart';

class MeasurementPanel extends StatelessWidget {
  const MeasurementPanel({
    super.key,
    required this.mode,
    required this.points,
    required this.onModeChanged,
    required this.onUndo,
    required this.onClear,
    required this.onClose,
  });

  final MeasureMode mode;
  final List<LatLng> points;
  final ValueChanged<MeasureMode> onModeChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bottom  = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── drag handle ─────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // ── Mode tabs + close ─────────────────────────────────────────────
          Row(
            children: [
              _Tab(
                label: '📍 კოორდ.',
                active: mode == MeasureMode.coordinate,
                onTap:  () => onModeChanged(MeasureMode.coordinate),
                scheme: scheme,
              ),
              const SizedBox(width: 6),
              _Tab(
                label: '📏 ხაზი',
                active: mode == MeasureMode.line,
                onTap:  () => onModeChanged(MeasureMode.line),
                scheme: scheme,
              ),
              const SizedBox(width: 6),
              _Tab(
                label: '🔷 პოლიგ.',
                active: mode == MeasureMode.polygon,
                onTap:  () => onModeChanged(MeasureMode.polygon),
                scheme: scheme,
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'დახურვა',
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Results ──────────────────────────────────────────────────────────
          _buildResults(context, scheme, isDark),

          const SizedBox(height: 10),

          // ── Action buttons ───────────────────────────────────────────────────
          if (points.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionBtn(
                  icon: Icons.undo,
                  label: 'გაუქმება',
                  onTap: onUndo,
                  scheme: scheme,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.delete_outline,
                  label: 'გასუფთავება',
                  onTap: onClear,
                  scheme: scheme,
                  isDestructive: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Results builder ────────────────────────────────────────────────────────

  Widget _buildResults(BuildContext context, ColorScheme scheme, bool isDark) {
    switch (mode) {
      case MeasureMode.coordinate:
        return _buildCoordResults(scheme, isDark);
      case MeasureMode.line:
        return _buildLineResults(scheme, isDark);
      case MeasureMode.polygon:
        return _buildPolygonResults(scheme, isDark);
      case MeasureMode.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCoordResults(ColorScheme scheme, bool isDark) {
    if (points.isEmpty) {
      return _hint('რუკაზე ნებისმიერ ადგილას დააჭირეთ კოორდინატის მისაღებად');
    }
    final p   = points.last;
    final utm = UtmService.toUtm38N(p.latitude, p.longitude);
    final wgs = MeasurementService.formatWgs84(p.latitude, p.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResultRow(
          label: 'WGS 84',
          value: wgs,
          scheme: scheme,
          isDark: isDark,
          onCopy: wgs,
        ),
        const SizedBox(height: 6),
        _ResultRow(
          label: 'UTM 38N',
          value: utm.formatted(),
          scheme: scheme,
          isDark: isDark,
          onCopy: 'E ${utm.easting.toStringAsFixed(1)}  N ${utm.northing.toStringAsFixed(1)}',
        ),
      ],
    );
  }

  Widget _buildLineResults(ColorScheme scheme, bool isDark) {
    if (points.isEmpty) {
      return _hint('დააჭირეთ რუკაზე — პირველი წერტილი');
    }
    if (points.length == 1) {
      return _hint('კიდევ 1 წერტილი სიგრძის გამოსაანგარიშებლად');
    }
    final total = MeasurementService.totalLength(points);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResultRow(
          label: 'სიგრძე  (UTM 38N)',
          value: MeasurementService.formatLength(total),
          scheme: scheme,
          isDark: isDark,
          valueBold: true,
          onCopy: '${total.toStringAsFixed(2)} m',
        ),
        if (points.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${points.length - 1} სეგმენტი  •  ${points.length} წერტილი',
              style: TextStyle(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.45)),
            ),
          ),
      ],
    );
  }

  Widget _buildPolygonResults(ColorScheme scheme, bool isDark) {
    if (points.length < 3) {
      final need = 3 - points.length;
      return _hint(
        points.isEmpty
            ? 'დააჭირეთ რუკაზე — პირველი წერტილი'
            : 'კიდევ $need წერტილი საჭიროა ფართობის გამოსაანგარიშებლად',
      );
    }
    final area      = MeasurementService.polygonArea(points);
    final perimeter = MeasurementService.polygonPerimeter(points);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ResultRow(
                label: 'ფართობი  (UTM 38N)',
                value: MeasurementService.formatArea(area),
                scheme: scheme,
                isDark: isDark,
                valueBold: true,
                onCopy: '${area.toStringAsFixed(2)} m2',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ResultRow(
                label: 'პერიმეტრი',
                value: MeasurementService.formatLength(perimeter),
                scheme: scheme,
                isDark: isDark,
                valueBold: true,
                onCopy: '${perimeter.toStringAsFixed(2)} m',
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${points.length} წერტილი',
            style: TextStyle(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.45)),
          ),
        ),
      ],
    );
  }

  Widget _hint(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, color: Colors.grey),
    ),
  );
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.scheme,
    required this.isDark,
    required this.onCopy,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final ColorScheme scheme;
  final bool isDark;
  final String onCopy;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: scheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 1),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: onCopy));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('კოპირებულია 📋'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: valueBold ? 15 : 13,
                    fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.copy, size: 12, color: scheme.primary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.scheme,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? scheme.error : scheme.primary;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: const TextStyle(fontSize: 12),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
