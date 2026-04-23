import 'package:flutter/material.dart';

import 'map_fab.dart';

class MapControlPanel extends StatelessWidget {
  const MapControlPanel({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFocus,
    required this.onGps,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFocus;
  final Future<void> Function() onGps;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10,
      right: 15,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MapFab(icon: Icons.add, onPressed: onZoomIn, heroTag: "zoom_in"),
          const SizedBox(height: 8),
          MapFab(icon: Icons.remove, onPressed: onZoomOut, heroTag: "zoom_out"),
          const SizedBox(height: 8),
          MapFab(
            icon: Icons.center_focus_strong,
            onPressed: onFocus,
            heroTag: "focus",
            backgroundColor: Colors.orange,
            iconColor: Colors.white,
          ),
          const SizedBox(height: 8),
          MapFab(icon: Icons.gps_fixed, onPressed: onGps, heroTag: "gps"),
        ],
      ),
    );
  }
}
