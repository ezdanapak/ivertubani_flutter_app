import 'dart:async';

import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ivertubani/map_screen/widgets/ivertubani_drawer.dart';
import 'package:ivertubani/map_screen/widgets/ivertubani_map.dart';
import 'package:ivertubani/map_screen/widgets/ivertubani_text_field.dart';
import 'package:ivertubani/map_screen/widgets/map_control_panel.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../utils/app_launcher_service.dart';
import '../../utils/location_service.dart';
import '../../utils/map_action_service.dart';
import '../../utils/map_data_service.dart';
import '../../utils/marker_style.dart';
import '../widgets/feature_info_modal.dart';
import '../widgets/ivertubani_appbar.dart';

// ─── Isolate helper (top-level — required by compute()) ──────────────────────

/// Parameters that cross the isolate boundary.
/// All fields are primitive-safe (List / Map / String / List<int>).
class _FilterParams {
  final List<Map<String, dynamic>> allData;
  final String query;

  /// Enabled category ordinal indices (MapCategory.index).
  /// Using int instead of the enum so the object stays isolate-sendable.
  final List<int> enabledIndices;

  const _FilterParams({
    required this.allData,
    required this.query,
    required this.enabledIndices,
  });
}

/// Pure data filtering — executed in a background isolate via compute().
/// Returns only the rows whose coordinates are valid and that satisfy both
/// the active category filter and the search query.
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
    final name = (row['Name'] ?? '').toString().toLowerCase();
    final desc = (row['Description'] ?? '').toString().toLowerCase();

    final matchesCategory =
        enabledSet.contains(MapCategory.fromRaw(type, type).index);
    final matchesSearch =
        query.isEmpty ||
        name.contains(query) ||
        desc.contains(query) ||
        type.toLowerCase().contains(query);

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
  final LatLng _initialLocation = const LatLng(41.7301548, 44.8353731);
  LatLng? _currentLocation;
  Future<FileCacheStore>? _cacheStoreFuture;
  Set<MapCategory> _enabledCategories = MapCategory.values.toSet();

  /// Debounce timer — cancelled and restarted on every keystroke.
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _queryController = TextEditingController();

    _locationService = LocationService();
    _dataService = MapDataService();
    _mapActions = MapActionsService(_mapController);

    _enabledCategories = MapCategory.values.toSet();
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
    _cacheStoreFuture = getTemporaryDirectory().then((dir) {
      return FileCacheStore(p.join(dir.path, 'map_cache'));
    });
  }

  Future<void> _determinePosition() async {
    _currentLocation = await _locationService.getCurrentLocation();
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _allData = await _dataService.loadData();
    await _filterMarkers();
  }

  /// Filters raw rows in a background isolate, then builds Marker widgets
  /// on the main thread (widget construction needs BuildContext).
  Future<void> _filterMarkers() async {
    final params = _FilterParams(
      allData: _allData,
      query: _queryController.text,
      enabledIndices: _enabledCategories.map((c) => c.index).toList(),
    );

    // CPU-bound loop runs off the UI thread.
    final filteredRows = await compute(_filterDataIsolate, params);

    // Marker widgets are built here (main thread) because GestureDetector
    // callbacks need a valid BuildContext.
    final newMarkers = filteredRows.map((row) {
      final lat = double.parse(row['lat'].toString());
      final lon = double.parse(
        (row['long'] ?? row['lon']).toString(),
      );
      final type = (row['Type'] ?? row['type'] ?? '').toString();
      final style = MapCategory.fromRaw(type, type).style;

      return Marker(
        point: LatLng(lat, lon),
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () => FeatureInfoModal.openFutureInfoModal(
            context,
            attributes: row,
          ),
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

  /// Debounced search handler — waits 300 ms after the last keystroke
  /// before triggering _filterMarkers().
  ///
  /// როგორ მუშაობს:
  ///   მომხმარებელი წერს → _debounceTimer გადაიწყობა → 300 ms-ის შემდეგ
  ///   (თუ ახალი სიმბოლო არ შეიყვანა) → _filterMarkers() გამოიძახება.
  ///   ეს ხელს უშლის CPU-ს ზედმეტ დატვირთვას ყოველ ასოზე.
  void _onSearchChanged(String _) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 300),
      _filterMarkers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double systemBottom = MediaQuery.of(
      context,
    ).systemGestureInsets.bottom;
    return Scaffold(
      appBar: IvertubaniAppBar(
        onAddLocation: () async =>
            await AppLauncherService.instance.openGoogleForm(context),
        onRefresh: _loadData,
      ),
      endDrawer: IvertubaniDrawer(
        enabledCategories: _enabledCategories,
        onCategoryPress: (res) {
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
            if (_isLoading) const Center(child: CircularProgressIndicator()),
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
