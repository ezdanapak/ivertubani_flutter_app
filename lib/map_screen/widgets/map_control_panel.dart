import 'package:flutter/material.dart';

import '../../utils/measurement_service.dart';
import 'map_fab.dart';

class MapControlPanel extends StatelessWidget {
  const MapControlPanel({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFocus,
    required this.onGps,
    required this.onShare,
    required this.onMeasure,
    required this.measureMode,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFocus;
  final Future<void> Function() onGps;
  final VoidCallback onShare;
  final VoidCallback onMeasure;
  final MeasureMode measureMode;

  @override
  Widget build(BuildContext context) {
    final isMeasuring = measureMode != MeasureMode.none;

    return Positioned(
      bottom: 10,
      right: 15,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Navigation ────────────────────────────────────────────────
          MapFab(
            icon: Icons.add,
            onPressed: () async => onZoomIn(),
            heroTag: 'zoom_in',
          ),
          const SizedBox(height: 8),
          MapFab(
            icon: Icons.remove,
            onPressed: () async => onZoomOut(),
            heroTag: 'zoom_out',
          ),
          const SizedBox(height: 8),
          MapFab(
            icon: Icons.center_focus_strong,
            onPressed: () async => onFocus(),
            heroTag: 'focus',
            backgroundColor: Colors.orange,
            iconColor: Colors.white,
          ),
          const SizedBox(height: 8),
          MapFab(
            icon: Icons.gps_fixed,
            onPressed: onGps,
            heroTag: 'gps',
          ),

          // ── Separator ─────────────────────────────────────────────────
          const SizedBox(height: 12),
          SizedBox(
            width: 44,
            child: Divider(
              color: Colors.grey.withValues(alpha: 0.4),
              thickness: 1,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),

          // ── Tools ─────────────────────────────────────────────────────
          MapFab(
            icon: Icons.share,
            onPressed: () async => onShare(),
            heroTag: 'share',
            tooltip: 'რუკის გაზიარება',
          ),
          const SizedBox(height: 8),
          MapFab(
            icon: Icons.straighten,
            onPressed: () async => onMeasure(),
            heroTag: 'measure',
            tooltip: 'საზომი ხელსაწყოები',
            backgroundColor: isMeasuring ? Colors.indigo : null,
            iconColor: isMeasuring ? Colors.white : null,
          ),
        ],
      ),
    );
  }
}
