import 'dart:math' as math;

/// WGS84 → UTM Zone 38N (EPSG:32638) projection.
///
/// Transverse Mercator series expansion (Helmert / Snyder).
/// Accuracy: < 1 mm within Zone 38N bounds (Georgia, Armenia, Azerbaijan).
///
/// Zone 38N:  central meridian λ₀ = 45 °E
///            false easting  E₀ = 500 000 m
///            false northing N₀ = 0 m   (Northern hemisphere)
///            scale factor   k₀ = 0.9996
class UtmService {
  UtmService._();

  // ─── WGS84 ellipsoid ─────────────────────────────────────────────────────────
  static const double _a  = 6378137.0;             // semi-major axis (m)
  static const double _f  = 1.0 / 298.257223563;   // flattening
  static const double _k0 = 0.9996;                // scale factor
  static const double _e0 = 500000.0;              // false easting (m)

  // Zone 38N central meridian
  static const double _lon0 = 45.0 * math.pi / 180.0;

  // Derived ellipsoid constants (computed once at class load)
  static final double _e2      = 2 * _f - _f * _f;           // first eccentricity²
  static final double _ePrime2 = _e2 / (1.0 - _e2);          // second eccentricity²

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Converts WGS84 decimal-degree coordinates to UTM Zone 38N.
  ///
  /// [latDeg] : latitude  (positive = North)
  /// [lonDeg] : longitude (positive = East)
  ///
  /// Returns [UtmCoord] with [easting] and [northing] in metres.
  static UtmCoord toUtm38N(double latDeg, double lonDeg) {
    final lat = latDeg * math.pi / 180.0;
    final lon = lonDeg * math.pi / 180.0;

    final sinLat = math.sin(lat);
    final cosLat = math.cos(lat);
    final tanLat = math.tan(lat);
    final t      = tanLat * tanLat;
    final c      = _ePrime2 * cosLat * cosLat;

    // Prime vertical radius of curvature
    final nu = _a / math.sqrt(1.0 - _e2 * sinLat * sinLat);

    // Longitude offset from central meridian
    final A  = cosLat * (lon - _lon0);
    final A2 = A * A;
    final A3 = A2 * A;
    final A4 = A3 * A;
    final A5 = A4 * A;
    final A6 = A5 * A;

    // ─── Meridional arc ───────────────────────────────────────────────────────
    final e2  = _e2;
    final e4  = e2 * e2;
    final e6  = e4 * e2;

    final M = _a * (
          (1 - e2 / 4 - 3 * e4 / 64 - 5 * e6 / 256)       * lat
        - (3 * e2 / 8 + 3 * e4 / 32 + 45 * e6 / 1024)     * math.sin(2 * lat)
        + (15 * e4 / 256 + 45 * e6 / 1024)                 * math.sin(4 * lat)
        - (35 * e6 / 3072)                                   * math.sin(6 * lat)
    );

    // ─── Easting ──────────────────────────────────────────────────────────────
    final easting = _k0 * nu * (
          A
        + (1 - t + c)                                         * A3 / 6.0
        + (5 - 18 * t + t * t + 72 * c - 58 * _ePrime2)     * A5 / 120.0
    ) + _e0;

    // ─── Northing ─────────────────────────────────────────────────────────────
    final northing = _k0 * (
        M + nu * tanLat * (
              A2 / 2.0
            + (5 - t + 9 * c + 4 * c * c)                       * A4 / 24.0
            + (61 - 58 * t + t * t + 600 * c - 330 * _ePrime2)  * A6 / 720.0
        )
    );

    return UtmCoord(easting: easting, northing: northing);
  }
}

// ─── Value object ─────────────────────────────────────────────────────────────

class UtmCoord {
  const UtmCoord({required this.easting, required this.northing});

  final double easting;   // metres east  of central meridian + 500 000
  final double northing;  // metres north of equator

  /// Formatted string: "E 683 245.3   N 4 621 834.7"
  String formatted() {
    return 'E ${_fmt(easting)}   N ${_fmt(northing)}';
  }

  static String _fmt(double v) {
    // Group digits in thousands for readability
    final s = v.toStringAsFixed(1);
    final parts = s.split('.');
    final intStr = parts[0];
    final dec    = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intStr.length; i++) {
      if (i > 0 && (intStr.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(intStr[i]);
    }
    return '${buffer.toString()}.$dec';
  }

  @override
  String toString() => formatted();
}
