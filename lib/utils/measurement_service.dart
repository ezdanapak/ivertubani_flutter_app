import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'utm_service.dart';

// ─── Mode enum ────────────────────────────────────────────────────────────────

enum MeasureMode {
  none,
  coordinate, // single point → WGS84 + UTM 38N
  line,       // polyline → length in UTM metres
  polygon,    // closed polygon → area + perimeter in UTM metres
}

// ─── Calculations ─────────────────────────────────────────────────────────────

class MeasurementService {
  MeasurementService._();

  /// Euclidean distance (m) between two UTM points.
  static double _segmentLength(UtmCoord a, UtmCoord b) {
    final dx = b.easting  - a.easting;
    final dy = b.northing - a.northing;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Total length (m) of an open polyline [points].
  ///
  /// Calculated in the UTM 38N projected plane — gives metric accuracy
  /// without the complexity of spherical formulae.
  static double totalLength(List<LatLng> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final a = UtmService.toUtm38N(points[i].latitude,     points[i].longitude);
      final b = UtmService.toUtm38N(points[i+1].latitude,   points[i+1].longitude);
      total += _segmentLength(a, b);
    }
    return total;
  }

  /// Area (m²) of a polygon using the Shoelace formula in UTM 38N.
  ///
  /// Accurate for regions within Zone 38N (< 0.1 % distortion for Georgia).
  static double polygonArea(List<LatLng> points) {
    if (points.length < 3) return 0;
    final utm = points
        .map((p) => UtmService.toUtm38N(p.latitude, p.longitude))
        .toList();
    double area = 0;
    final n = utm.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += utm[i].easting  * utm[j].northing;
      area -= utm[j].easting  * utm[i].northing;
    }
    return area.abs() / 2.0;
  }

  /// Perimeter (m) of a closed polygon.
  static double polygonPerimeter(List<LatLng> points) {
    if (points.length < 2) return 0;
    // close the ring
    final closed = [...points, points.first];
    return totalLength(closed);
  }

  // ─── Formatters ─────────────────────────────────────────────────────────────

  /// Formats a length value with adaptive units (m / km).
  static String formatLength(double meters) {
    if (meters >= 1000) {
      return '${_n(meters / 1000, 3)} კმ';
    }
    return '${_n(meters, 1)} მ';
  }

  /// Formats an area value with adaptive units (m² / ha / km²).
  static String formatArea(double m2) {
    if (m2 >= 1000000) {
      return '${_n(m2 / 1000000, 4)} კმ²';
    }
    if (m2 >= 10000) {
      final ha = m2 / 10000;
      return '${_n(ha, 2)} ჰა  (${_fmtM2(m2)})';
    }
    return _fmtM2(m2);
  }

  static String _fmtM2(double m2) => '${_n(m2, 1)} მ²';

  /// WGS84 coordinate string (decimal degrees).
  static String formatWgs84(double lat, double lon) {
    final latStr = '${lat.toStringAsFixed(6)}°${lat >= 0 ? "N" : "S"}';
    final lonStr = '${lon.abs().toStringAsFixed(6)}°${lon >= 0 ? "E" : "W"}';
    return '$latStr   $lonStr';
  }

  /// Formats [v] with [decimals] decimal places, with thousands separators.
  static String _n(double v, int decimals) {
    final s = v.toStringAsFixed(decimals);
    final parts = s.split('.');
    final intStr = parts[0];
    final dec    = parts.length > 1 ? '.${parts[1]}' : '';
    final buffer = StringBuffer();
    for (int i = 0; i < intStr.length; i++) {
      if (i > 0 && (intStr.length - i) % 3 == 0 && intStr[0] != '-') {
        buffer.write(' ');
      }
      buffer.write(intStr[i]);
    }
    return '${buffer.toString()}$dec';
  }
}
