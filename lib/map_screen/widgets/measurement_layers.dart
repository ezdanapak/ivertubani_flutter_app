import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../utils/measurement_service.dart';

/// Returns the list of [FlutterMap] child layers for the active measurement.
///
/// Spread directly into [FlutterMap.children]:
/// ```dart
/// children: [
///   TileLayer(...),
///   ...buildMeasurementLayers(mode: mode, points: points, scheme: scheme),
/// ]
/// ```
List<Widget> buildMeasurementLayers({
  required MeasureMode mode,
  required List<LatLng> points,
  required ColorScheme scheme,
}) {
  if (mode == MeasureMode.none || points.isEmpty) return const [];

  final layers = <Widget>[];
  final color  = scheme.primary;

  // ─── Polygon fill ──────────────────────────────────────────────────────────
  if (mode == MeasureMode.polygon && points.length >= 3) {
    layers.add(
      PolygonLayer(
        polygons: [
          Polygon(
            points: points,
            color: color.withValues(alpha: 0.15),
            borderColor: color,
            borderStrokeWidth: 2.0,
          ),
        ],
      ),
    );
  }

  // ─── Polyline ──────────────────────────────────────────────────────────────
  if (points.length >= 2) {
    final linePoints = mode == MeasureMode.polygon && points.length >= 3
        ? [...points, points.first]  // close the ring visually
        : points;

    layers.add(
      PolylineLayer(
        polylines: [
          Polyline(
            points: linePoints,
            strokeWidth: 2.5,
            color: color,
          ),
        ],
      ),
    );
  }

  // ─── Numbered point markers ────────────────────────────────────────────────
  layers.add(
    MarkerLayer(
      markers: points.asMap().entries.map((entry) {
        final index = entry.key;
        final point = entry.value;

        return Marker(
          point: point,
          width: 26,
          height: 26,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
              ],
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );

  return layers;
}
