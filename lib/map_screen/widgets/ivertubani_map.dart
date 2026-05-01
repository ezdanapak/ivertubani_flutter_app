import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:ivertubani/utils/dio_service.dart';
import 'package:latlong2/latlong.dart';

import '../../utils/measurement_service.dart';
import 'measurement_layers.dart';

// Tile URLs
const _lightTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _darkTiles  = 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

class IvertubaniMap extends StatefulWidget {
  const IvertubaniMap({
    super.key,
    required this.cacheStoreFuture,
    required this.mapController,
    required this.initialLocation,
    required this.markers,
    required this.currentLocation,
    // ── Measurement ───────────────────────────────────────────────────────────
    required this.measureMode,
    required this.measurePoints,
    required this.onMapTap,
  });

  final Future<FileCacheStore>? cacheStoreFuture;
  final MapController mapController;
  final LatLng initialLocation;
  final List<Marker> markers;
  final LatLng? currentLocation;

  final MeasureMode measureMode;
  final List<LatLng> measurePoints;
  final void Function(TapPosition, LatLng) onMapTap;

  @override
  State<IvertubaniMap> createState() => _IvertubaniMapState();
}

class _IvertubaniMapState extends State<IvertubaniMap> {
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio = DioService.create();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<FileCacheStore>(
      future: widget.cacheStoreFuture,
      builder: (context, snapshot) {
        return FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: widget.initialLocation,
            initialZoom: 15,
            onTap: widget.onMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: isDark ? _darkTiles : _lightTiles,
              userAgentPackageName: 'ge.qgis.ivertubani',
              tileProvider: snapshot.hasData
                  ? CachedTileProvider(store: snapshot.data!, dio: _dio)
                  : NetworkTileProvider(),
            ),
            MarkerLayer(markers: widget.markers),

            if (widget.currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.currentLocation!,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 25,
                    ),
                  ),
                ],
              ),

            // ── Measurement overlay layers ────────────────────────────────────
            ...buildMeasurementLayers(
              mode:   widget.measureMode,
              points: widget.measurePoints,
              scheme: scheme,
            ),
          ],
        );
      },
    );
  }
}
