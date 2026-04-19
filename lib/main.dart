import 'dart:io';
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
      
      // ფაილის ხელახლა ჩაწერა assets-იდან
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      
      ByteData data = await rootBundle.load('assets/data.gpkg');
      await file.writeAsBytes(data.buffer.asUint8List());

      final db = await openDatabase(path);
      
      // ვკითხულობთ მხოლოდ 'poi' ცხრილს
      List<Map<String, dynamic>> rows = await db.query('poi');
      debugPrint("ბაზიდან წაკითხულია ${rows.length} ხაზი");
      
      List<Marker> newMarkers = [];

      for (var row in rows) {
        // პირდაპირი წაკითხვა
        final lat = double.tryParse(row['lat']?.toString() ?? '');
        final lon = double.tryParse(row['long']?.toString() ?? row['lon']?.toString() ?? '');
        final type = row['Type']?.toString() ?? row['type']?.toString() ?? 'სხვა';

        if (lat != null && lon != null) {
          totalFound++;
          debugPrint("ნაპოვნია ტიპი: $type ($lat, $lon)");
          final markerStyle = _getMarkerStyle(type);
          
          newMarkers.add(
            Marker(
              point: LatLng(lat, lon),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showFeatureInfo(row),
                child: Icon(
                  markerStyle.icon, 
                  color: markerStyle.color, 
                  size: 45
                ),
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

  _MarkerStyle _getMarkerStyle(String type) {
    final t = type.toLowerCase().trim();
    
    // ცნობილი კატეგორიების რუკა
    final Map<String, _MarkerStyle> knownStyles = {
      'აფთიაქი': _MarkerStyle(Icons.local_pharmacy, Colors.green),
      'მარკეტი': _MarkerStyle(Icons.shopping_cart, Colors.blue),
      'მაღაზია': _MarkerStyle(Icons.shopping_cart, Colors.blue),
      'ბანკი': _MarkerStyle(Icons.account_balance, Colors.orange),
      'რესტორანი': _MarkerStyle(Icons.restaurant, Colors.red),
      'კაფე': _MarkerStyle(Icons.restaurant, Colors.red),
      'სკოლა': _MarkerStyle(Icons.school, Colors.purple),
      'ბაღი': _MarkerStyle(Icons.school, Colors.purple),
      'ბენზინგასამართი': _MarkerStyle(Icons.local_gas_station, Colors.orangeAccent),
      'გასამართი სადგური': _MarkerStyle(Icons.local_gas_station, Colors.orangeAccent),
      'ეკლესია': _MarkerStyle(Icons.church, Colors.brown),
      'ტაძარი': _MarkerStyle(Icons.church, Colors.brown),
      'სასტუმრო': _MarkerStyle(Icons.hotel, Colors.cyan),
      'პარკი': _MarkerStyle(Icons.park, Colors.lightGreen),
      'სკვერი': _MarkerStyle(Icons.park, Colors.lightGreen),
      'სალონი': _MarkerStyle(Icons.content_cut, Colors.pinkAccent),
      'საცხობი': _MarkerStyle(Icons.bakery_dining, Colors.amber),
      'ავტოსამრეცხაო': _MarkerStyle(Icons.local_car_wash, Colors.blueGrey),
      'ფოსტა': _MarkerStyle(Icons.local_post_office, Colors.deepOrange),
      'საავადმყოფო': _MarkerStyle(Icons.local_hospital, Colors.redAccent),
      'სტომატოლოგი': _MarkerStyle(Icons.medical_services, Colors.teal),
    };

    if (knownStyles.containsKey(t)) {
      return knownStyles[t]!;
    }

    // თუ ტიპი უცნობია, შევქმნათ უნიკალური ფერი სახელის ჰეშით
    final int hash = t.hashCode;
    final Color autoColor = Color((hash & 0xFFFFFF) | 0xFF000000).withOpacity(0.9);
    return _MarkerStyle(Icons.location_on, autoColor);
  }

  void _showFeatureInfo(Map<String, dynamic> attributes) {
    // ტექნიკური სვეტები, რომლებიც არ გვინდა პოპაპში გამოჩნდეს
    final technicalFields = ['fid', 'geom', 'geometry', 'lat', 'long', 'lon', 'id', 'ogc_fid'];
    
    // ვიღებთ ყველა სვეტს, გარდა ტექნიკურისა და ბინარულისა
    final displayData = attributes.entries.where((e) {
      final key = e.key.toLowerCase();
      final val = e.value?.toString().trim() ?? '';
      return !technicalFields.contains(key) && val.isNotEmpty && e.value is! Uint8List;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // პატარა ხაზი ზემოთ (Handle)
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            if (displayData.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("ინფორმაცია არ მოიძებნა", style: TextStyle(color: Colors.grey)),
              )
            else
              ...displayData.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        e.key.toUpperCase(), 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.indigo, letterSpacing: 0.5)
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        "${e.value}", 
                        style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)
                      ),
                    ),
                  ],
                ),
              )).toList(),
          ],
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
            tooltip: "განახლება",
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadGpkgData,
          ),
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

class _MarkerStyle {
  final IconData icon;
  final Color color;
  _MarkerStyle(this.icon, this.color);
}
