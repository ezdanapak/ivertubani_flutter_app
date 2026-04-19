import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ივერთუბნის რუკა',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  List<Marker> _markers = [];
  bool _isLoading = true;
  bool _showPoints = true;
  LatLng? _currentLocation;
  final LatLng _initialLocation = const LatLng(41.7301548, 44.8353731);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadGpkgData();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<void> _loadGpkgData() async {
    setState(() => _isLoading = true);
    int totalFound = 0;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = p.join(directory.path, 'data.gpkg');
      
      ByteData data = await rootBundle.load('assets/data.gpkg');
      await File(path).writeAsBytes(data.buffer.asUint8List());

      final db = await openDatabase(path);
      
      // ვკითხულობთ მხოლოდ 'poi' ცხრილს
      List<Map<String, dynamic>> rows = await db.query('poi');
      debugPrint("ბაზიდან წაკითხულია ${rows.length} ხაზი");
      
      List<Marker> newMarkers = [];

      for (var row in rows) {
        // პირდაპირი წაკითხვა ყოველგვარი გადამოწმების გარეშე
        final lat = double.tryParse(row['lat']?.toString() ?? '');
        final lon = double.tryParse(row['long']?.toString() ?? row['lon']?.toString() ?? '');

        if (lat != null && lon != null) {
          totalFound++;
          newMarkers.add(
            Marker(
              point: LatLng(lat, lon),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showFeatureInfo(row),
                child: const Icon(Icons.location_on, color: Colors.red, size: 45),
              ),
            ),
          );
        }
      }

      setState(() {
        _markers = newMarkers;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ჩაიტვირთა $totalFound წერტილი')),
        );
      }
      await db.close();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("შეცდომა: $e");
    }
  }

  void _showFeatureInfo(Map<String, dynamic> attributes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          shrinkWrap: true,
          children: attributes.entries
            .where((e) => e.value != null && e.value is! Uint8List)
            .map((e) => ListTile(
                  title: Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  subtitle: Text("${e.value}"),
                  dense: true,
                ))
            .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ივერთუბნის რუკა', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "ჩართვა/გამორთვა",
            icon: Icon(_showPoints ? Icons.visibility : Icons.visibility_off, color: Colors.white),
            onPressed: () => setState(() => _showPoints = !_showPoints),
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialLocation,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ivertubani',
              ),
              if (_showPoints) MarkerLayer(markers: _markers),
              if (_currentLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _currentLocation!,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 25),
                  )
                ]),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                _mapFab(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1), "zoom_in"),
                const SizedBox(height: 10),
                _mapFab(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1), "zoom_out"),
                const SizedBox(height: 10),
                _mapFab(Icons.center_focus_strong, () {
                  if (_markers.isNotEmpty) {
                    final bounds = LatLngBounds.fromPoints(_markers.map((m) => m.point).toList());
                    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100)));
                  }
                }, "focus_points", color: Colors.orange),
                const SizedBox(height: 10),
                _mapFab(Icons.gps_fixed, () async {
                  await _determinePosition();
                  if (_currentLocation != null) _mapController.move(_currentLocation!, 16);
                }, "my_gps", color: Colors.indigo, iconColor: Colors.white),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _mapFab(IconData icon, VoidCallback onPressed, String tag, {Color color = Colors.white, Color iconColor = Colors.indigo}) {
    return FloatingActionButton(
      mini: true,
      heroTag: tag,
      backgroundColor: color,
      onPressed: onPressed,
      child: Icon(icon, color: iconColor),
    );
  }
}
