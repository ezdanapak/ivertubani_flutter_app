import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
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
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _allData = await _dataService.loadData();
    _filterMarkers();
  }

  void _filterMarkers() {
    List<Marker> newMarkers = [];
    for (var row in _allData) {
      final lat = double.tryParse(row['lat']?.toString() ?? '');
      final lon = double.tryParse(
        row['long']?.toString() ?? row['lon']?.toString() ?? '',
      );
      final type = (row['Type'] ?? row['type'] ?? '').toString();
      final name = (row['Name'] ?? '').toString().toLowerCase();
      final desc = (row['Description'] ?? '').toString().toLowerCase();
      final categoryEnum = MapCategory.fromRaw(type, type);
      final matchesCategory = _enabledCategories.contains(categoryEnum);
      final matchesSearch =
          _queryController.text.isEmpty ||
          name.contains(_queryController.text) ||
          desc.contains(_queryController.text) ||
          type.toLowerCase().contains(_queryController.text);
      if (lat != null && lon != null && matchesCategory && matchesSearch) {
        final style = categoryEnum.style;
        newMarkers.add(
          Marker(
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
          ),
        );
      }
    }
    setState(() {
      _markers = newMarkers;
      _isLoading = false;
    });
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
            _filterMarkers();
          });
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
              onTextFieldChange: (val) {
                _filterMarkers();
              },
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
