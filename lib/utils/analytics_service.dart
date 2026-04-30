import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized Firebase Analytics wrapper.
///
/// ყველა event ერთი ადგილიდან — სახელები შეცვლა მარტივია.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ─── Session ───────────────────────────────────────────────────────────────

  /// აპლიკაცია გაიხსნა და რუკა ჩაიტვირთა
  Future<void> logMapSessionStart() async {
    await _safe(() => _analytics.logAppOpen());
  }

  // ─── Map interactions ──────────────────────────────────────────────────────

  /// მომხმარებელმა მარკერს დააჭირა
  Future<void> logMarkerTapped({
    required String name,
    required String category,
  }) async {
    await _safe(() => _analytics.logEvent(
          name: 'marker_tapped',
          parameters: {
            'poi_name': name,
            'poi_category': category,
          },
        ));
  }

  /// Google Maps ბმულს გახსნა
  Future<void> logGoogleMapsOpened({required String poiName}) async {
    await _safe(() => _analytics.logEvent(
          name: 'google_maps_opened',
          parameters: {'poi_name': poiName},
        ));
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  /// ძებნა შესრულდა (debounce-ის შემდეგ)
  Future<void> logSearch({required String query}) async {
    if (query.isEmpty) return;
    await _safe(() => _analytics.logSearch(searchTerm: query));
  }

  // ─── Filters ───────────────────────────────────────────────────────────────

  /// კატეგორიის ფილტრი შეიცვალა
  Future<void> logCategoryFilterChanged({
    required String category,
    required bool enabled,
  }) async {
    await _safe(() => _analytics.logEvent(
          name: 'category_filter_changed',
          parameters: {
            'category': category,
            'enabled': enabled ? 1 : 0,
          },
        ));
  }

  // ─── Location ──────────────────────────────────────────────────────────────

  /// GPS ღილაკს დააჭირა
  Future<void> logGpsTapped() async {
    await _safe(() => _analytics.logEvent(name: 'gps_button_tapped'));
  }

  // ─── Add location ──────────────────────────────────────────────────────────

  /// "წერტილის დამატება" ფორმა გაიხსნა
  Future<void> logAddLocationTapped() async {
    await _safe(() => _analytics.logEvent(name: 'add_location_tapped'));
  }

  // ─── Settings ──────────────────────────────────────────────────────────────

  /// ენა შეიცვალა
  Future<void> logLanguageChanged({required String locale}) async {
    await _safe(() => _analytics.logEvent(
          name: 'language_changed',
          parameters: {'locale': locale},
        ));
  }

  /// თემა შეიცვალა
  Future<void> logThemeChanged({required bool isDark}) async {
    await _safe(() => _analytics.logEvent(
          name: 'theme_changed',
          parameters: {'dark_mode': isDark ? 1 : 0},
        ));
  }

  // ─── Helper ────────────────────────────────────────────────────────────────

  /// Analytics შეცდომები არ უნდა ამჩნევდეს მომხმარებელს — ჩუმად ვლოგავთ.
  Future<void> _safe(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      debugPrint('[Analytics] error: $e');
    }
  }
}
