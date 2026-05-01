import 'dart:async';

import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ivertubani/generated/app_localizations.dart';
import 'package:ivertubani/map_screen/widgets/ivertubani_drawer.dart';
import 'package:ivertubani/map_screen/widgets/ivertubani_map.dart';
import 'package:ivertubani/map_screen/widgets/ivertubani_text_field.dart';
import 'package:ivertubani/map_screen/widgets/map_control_panel.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../utils/analytics_service.dart';
import '../../utils/app_launcher_service.dart';
import '../../utils/location_service.dart';
import '../../utils/map_action_service.dart';
import '../../utils/map_data_service.dart';
import '../../utils/marker_style.dart';
import '../../utils/review_service.dart';
import '../widgets/feature_info_modal.dart';
import '../widgets/ivertubani_appbar.dart';
import '../widgets/promotion_modal.dart';

// ─── Isolate helper ───────────────────────────────────────────────────────────

class _FilterParams {
  final List<Map<String, dynamic>> allData;
  final String query;
  final List<int> enabledIndices;

  /// category.index → search terms (ქართული subCategories + ლოკალიზებული label).
  /// main thread-ზე აიგება, რათა l10n isolate-ში არ გახვიდეს.
  final Map<int, List<String>> categorySearchTerms;

  const _FilterParams({
    required this.allData,
    required this.query,
    required this.enabledIndices,
    required this.categorySearchTerms,
  });
}

// ტექნიკური ველები, რომლებიც ძებნაში არ გვჭირდება.
const _kTechnicalKeys = {
  'fid', 'geom', 'geometry', 'lat', 'long', 'lon', 'id', 'ogc_fid',
};

List<Map<String, dynamic>> _filterDataIsolate(_FilterParams params) {
  final query = params.query.toLowerCase();
  final enabledSet = params.enabledIndices.toSet();

  return params.allData.where((row) {
    final lat = double.tryParse(row['lat']?.toString() ?? '');
    final lon = double.tryParse(
      row['long']?.toString() ?? row['lon']?.toString() ?? '',
    );
    if (lat == null || lon == null) return false;

    final type = (row['Type'] ?? row['type'] ?? '').toString();
    final category = MapCategory.fromRaw(type, type);
    final matchesCategory = enabledSet.contains(category.index);

    // ყველა არა-ტექნიკური სვეტის მნიშვნელობა ერთ სტრინგად —
    // Name, Description, Address, Phone და ნებისმიერი სხვა სვეტი
    // ავტომატურად მოხვდება ძებნაში, ინგლისური/ქართული ორივე.
    final categoryTerms = params.categorySearchTerms[category.index] ?? [];
    final matchesSearch =
        query.isEmpty ||
        categoryTerms.any((term) => term.contains(query)) ||
        row.entries
            .where((e) => !_kTechnicalKeys.contains(e.key.toLowerCase()))
            .any((e) =>
                e.value?.toString().toLowerCase().contains(query) ?? false);

    return matchesCategory && matchesSearch;
  }).toList();
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  late final TextEditingController _queryController;
  late final LocationService _locationService;
  late final MapDataService _dataService;
  late final MapActionsService _mapActions;

  List<Map<String, dynamic>> _allData = [];
  List<Marker> _markers = [];
  bool _isLoading = true;
  bool _hasError = false;
  final LatLng _initialLocation = const LatLng(41.7301548, 44.8353731);
  LatLng? _currentLocation;
  Future<FileCacheStore>? _cacheStoreFuture;
  Set<MapCategory> _enabledCategories = MapCategory.values.toSet();
  Timer? _debounceTimer;
  int _markerTapCount = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _queryController = TextEditingController();
    _locationService = LocationService();
    _dataService = MapDataService();
    _mapActions = MapActionsService(_mapController);
    _initCache();
    _loadData();
    _determinePosition();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _initCache() {
    // Web-ზე getTemporaryDirectory() არ არსებობს — tile cache მხოლოდ native-ზე.
    if (kIsWeb) return;
    _cacheStoreFuture = getTemporaryDirectory().then(
      (dir) => FileCacheStore(p.join(dir.path, 'map_cache')),
    );
  }

  Future<void> _determinePosition() async {
    _currentLocation = await _locationService.getCurrentLocation();
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    AnalyticsService.instance.logMapSessionStart();
    ReviewService.instance.onSessionStart();
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      _allData = await _dataService.loadData();
      await _filterMarkers();
    } catch (e) {
      debugPrint('_loadData error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loadError),
            action: SnackBarAction(
              label: l10n.retry,
              onPressed: _loadData,
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _filterMarkers() async {
    // ლოკალიზებული search terms: ქართული subCategories + მიმდინარე ლოკალის label.
    // ეს main thread-ზე იგება, რათა l10n isolate-ში არ გახვიდეს.
    final l10n = AppLocalizations.of(context);
    final categorySearchTerms = {
      for (final cat in MapCategory.values)
        cat.index: [
          ...cat.subCategories.map((s) => s.toLowerCase()),
          cat.labelFor(l10n).toLowerCase(),
        ],
    };

    final params = _FilterParams(
      allData: _allData,
      query: _queryController.text,
      enabledIndices: _enabledCategories.map((c) => c.index).toList(),
      categorySearchTerms: categorySearchTerms,
    );

    final filteredRows = await compute(_filterDataIsolate, params);

    final newMarkers = filteredRows.map((row) {
      final lat = double.parse(row['lat'].toString());
      final lon = double.parse((row['long'] ?? row['lon']).toString());
      final type = (row['Type'] ?? row['type'] ?? '').toString();
      final style = MapCategory.fromRaw(type, type).style;

      return Marker(
        point: LatLng(lat, lon),
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            AnalyticsService.instance.logMarkerTapped(
              name: (row['Name'] ?? '').toString(),
              category: type,
            );
            FeatureInfoModal.openFutureInfoModal(context, attributes: row);
            _markerTapCount++;
            if (_markerTapCount % 5 == 0) {
              Future.delayed(const Duration(milliseconds: 600), () {
                if (mounted) {
                  PromotionModal.showPromoModal(
                    context,
                    onButtonPress: () {
                      Navigator.of(context).pop();
                      AppLauncherService.instance.openGoogleForm(context);
                    },
                  );
                }
              });
            }
          },
          child: Icon(style.icon, color: style.color, size: 40),
        ),
      );
    }).toList();

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      AnalyticsService.instance.logSearch(query: query);
      _filterMarkers();
    });
  }

  // ─── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _queryController.text;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 44,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).noResults,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '"$query"',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final systemBottom = MediaQuery.of(context).systemGestureInsets.bottom;
    final showEmptyState =
        !_isLoading &&
        !_hasError &&
        _markers.isEmpty &&
        _queryController.text.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: IvertubaniAppBar(
        onAddLocation: () async {
          AnalyticsService.instance.logAddLocationTapped();
          await AppLauncherService.instance.openGoogleForm(context);
        },
        onRefresh: _loadData,
      ),
      endDrawer: IvertubaniDrawer(
        enabledCategories: _enabledCategories,
        onCategoryPress: (res) {
          AnalyticsService.instance.logCategoryFilterChanged(
            category: res.category.name,
            enabled: res.selected ?? false,
          );
          setState(() {
            res.selected!
                ? _enabledCategories.add(res.category)
                : _enabledCategories.remove(res.category);
          });
          _filterMarkers();
        },
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: systemBottom),
        child: Stack(
          children: [
            IvertubaniMap(
              cacheStoreFuture: _cacheStoreFuture,
              mapController: _mapController,
              initialLocation: _initialLocation,
              markers: _markers,
              currentLocation: _currentLocation,
            ),

            // Loading indicator
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),

            // Empty search state
            if (showEmptyState) _buildEmptyState(),

            IvertubaniTextField(
              controller: _queryController,
              onTextFieldChange: _onSearchChanged,
            ),

            MapControlPanel(
              onZoomIn: () => _mapActions.zoomIn(),
              onZoomOut: () => _mapActions.zoomOut(),
              onFocus: () => _mapActions.focus(
                markers: _markers,
                initialLocation: _initialLocation,
              ),
              onGps: () async {
                AnalyticsService.instance.logGpsTapped();
                await _determinePosition();
                if (_currentLocation != null) {
                  _mapActions.goToLocation(_currentLocation!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
