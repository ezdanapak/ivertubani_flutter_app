import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:latlong2/latlong.dart';

class IvertubaniMap extends StatelessWidget {
  const IvertubaniMap({
    super.key,
    required this.cacheStoreFuture,
    required this.mapController,
    required this.initialLocation,
    required this.markers,
    required this.currentLocation,
  });

  final Future<FileCacheStore>? cacheStoreFuture;
  final MapController mapController;
  final LatLng initialLocation;
  final List<Marker> markers;
  final LatLng? currentLocation;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FileCacheStore>(
      future: cacheStoreFuture,
      builder: (context, snapshot) {
        return FlutterMap(
          mapController: mapController,
          options: MapOptions(initialCenter: initialLocation, initialZoom: 15),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ivertubani',
              tileProvider: snapshot.hasData
                  ? CachedTileProvider(store: snapshot.data!)
                  : NetworkTileProvider(),
            ),
            MarkerLayer(markers: markers),

            if (currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLocation!,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 25,
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
