import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
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
  List<Map<String, dynamic>> _allData = []; 
  List<Marker> _markers = [];
  bool _isLoading = true;
  String _searchQuery = "";
  Set<String> _enabledGroups = {}; 
  
  final LatLng _initialLocation = const LatLng(41.7301548, 44.8353731);
  LatLng? _currentLocation;
  Future<FileCacheStore>? _cacheStoreFuture;

  final Map<String, List<String>> _categoryGroups = {
    'განათლება': ['ინგლისური', 'რუსული', 'ცეკვა', 'მასწავლებელი', 'სკოლა', 'ბაღი'],
    'ავტომობილი': ['ავტოსამრეცხაო', 'ავტოსახელოსნო', 'გაზგასამართი', 'ბენზინგასამართი', 'გასამართი სადგური'],
    'კვება': ['რესტორანი', 'კაფე', 'საცხობი', 'მარკეტი', 'მაღაზია'],
    'ჯანმრთელობა': ['აფთიაქი', 'საავადმყოფო', 'სტომატოლოგი'],
    'სხვა': ['ბანკი', 'სასტუმრო', 'პარკი', 'სკვერი', 'სალონი', 'ფოსტა']
  };

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _enabledGroups = _categoryGroups.keys.toSet(); 
    _initCache();
    _loadData();
    _determinePosition();
  }

  void _initCache() {
    _cacheStoreFuture = getTemporaryDirectory().then((dir) {
      return FileCacheStore(p.join(dir.path, 'map_cache'));
    });
  }

  Future<void> _launchGoogleForm() async {
    final Uri url = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSd9--oSe4vAVGW5ju1Wf4F0TRR56VO0KHTtXGbL3daJbW8fUA/viewform?usp=dialog');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint("URL Launcher Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ვერ მოხერხდა ბმულის გახსნა')),
        );
      }
    }
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
      setState(() => _currentLocation = LatLng(position.latitude, position.longitude));
    } catch (e) {
      debugPrint("GPS Error: $e");
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        final String response = await rootBundle.loadString('assets/data.geojson');
        final Map<String, dynamic> data = json.decode(response);
        final features = data['features'] as List<dynamic>;
        _allData = features.map((f) {
          final props = Map<String, dynamic>.from(f['properties']);
          final geometry = f['geometry'];
          if (geometry != null && geometry['type'] == 'Point') {
            final coords = geometry['coordinates'];
            props['long'] = coords[0];
            props['lat'] = coords[1];
          }
          return props;
        }).toList();
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path = p.join(directory.path, 'data.gpkg');
        final file = File(path);
        if (await file.exists()) await file.delete();
        ByteData data = await rootBundle.load('assets/data.gpkg');
        await file.writeAsBytes(data.buffer.asUint8List());
        final db = await openDatabase(path);
        _allData = await db.query('poi');
        await db.close();
      }
      _filterMarkers();
    } catch (e) {
      debugPrint("Data Loading Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterMarkers() {
    List<Marker> newMarkers = [];
    for (var row in _allData) {
      final lat = double.tryParse(row['lat']?.toString() ?? '');
      final lon = double.tryParse(row['long']?.toString() ?? row['lon']?.toString() ?? '');
      final type = (row['Type'] ?? row['type'] ?? 'სხვა').toString().toLowerCase().trim();
      final name = (row['Name'] ?? row['name'] ?? '').toString().toLowerCase();
      final desc = (row['Description'] ?? row['description'] ?? '').toString().toLowerCase();
      String? parentGroup;
      _categoryGroups.forEach((group, types) {
        if (types.any((t) => t.toLowerCase() == type)) parentGroup = group;
      });
      parentGroup ??= 'სხვა';
      bool matchesGroup = _enabledGroups.contains(parentGroup);
      bool matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || desc.contains(_searchQuery) || type.contains(_searchQuery);
      if (lat != null && lon != null && matchesGroup && matchesSearch) {
        final style = _getMarkerStyle(type);
        newMarkers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 45, height: 45,
            child: GestureDetector(
              onTap: () => _showFeatureInfo(row),
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

  _MarkerStyle _getMarkerStyle(String type) {
    final t = type.toLowerCase().trim();
    if (t.contains('აფთიაქი')) return _MarkerStyle(Icons.local_pharmacy, Colors.green);
    if (t.contains('მარკეტი') || t.contains('მაღაზია')) return _MarkerStyle(Icons.shopping_cart, Colors.blue);
    if (t.contains('ბანკი')) return _MarkerStyle(Icons.account_balance, Colors.orange);
    if (t.contains('რესტორანი') || t.contains('კაფე')) return _MarkerStyle(Icons.restaurant, Colors.red);
    if (t.contains('სკოლა') || t.contains('ბაღი') || t.contains('მასწავლებელი')) return _MarkerStyle(Icons.school, Colors.purple);
    if (t.contains('გასამართი')) return _MarkerStyle(Icons.local_gas_station, Colors.orangeAccent);
    if (t.contains('ეკლესია') || t.contains('ტაძარი')) return _MarkerStyle(Icons.church, Colors.brown);
    if (t.contains('პარკი') || t.contains('სკვერი')) return _MarkerStyle(Icons.park, Colors.lightGreen);
    if (t.contains('იყიდება')) return _MarkerStyle(Icons.sell, Colors.orangeAccent);
    if (t.contains('სილამაზის სალონი')) return _MarkerStyle(Icons.face, Colors.orangeAccent);
    final int hash = t.hashCode;
    final Color autoColor = Color((hash & 0xFFFFFF) | 0xFF000000).withOpacity(0.9);
    return _MarkerStyle(Icons.location_on, autoColor);
  }

  void _showFeatureInfo(Map<String, dynamic> attributes) {
    final technicalFields = ['fid', 'geom', 'geometry', 'lat', 'long', 'lon', 'id', 'ogc_fid'];
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
        padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 25), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            ...displayData.map((e) {
              // ვამოწმებთ არის თუ არა მნიშვნელობა ბმული (Google Map)
              final valString = e.value.toString().trim();
              final isLink = valString.startsWith('http') || e.key.toLowerCase().contains('google map');

              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.indigo))),
                    Expanded(
                      flex: 6, 
                      child: isLink 
                        ? GestureDetector(
                            onTap: () async {
                              final Uri url = Uri.parse(valString);
                              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                debugPrint('Could not launch $url');
                              }
                            },
                            child: const Text(
                              "იხილეთ Google Maps-ზე ➔", 
                              style: TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)
                            ),
                          )
                        : Text(valString, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double systemBottom = MediaQuery.of(context).systemGestureInsets.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ივერთუბანი', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt, color: Colors.white), 
            onPressed: _launchGoogleForm,
            tooltip: 'წერტილის დამატება',
          ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData, tooltip: 'განახლება'),
          Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => Scaffold.of(context).openEndDrawer(), tooltip: 'მენიუ')),
        ],
      ),
      endDrawer: _buildDrawer(), 
      body: Padding(
        padding: EdgeInsets.only(bottom: systemBottom),
        child: Stack(
          children: [
            FutureBuilder<FileCacheStore>(
              future: _cacheStoreFuture,
              builder: (context, snapshot) {
                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: _initialLocation, initialZoom: 15),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.ivertubani',
                      tileProvider: snapshot.hasData 
                          ? CachedTileProvider(store: snapshot.data!) 
                          : NetworkTileProvider(),
                    ),
                    MarkerLayer(markers: _markers),
                    if (_currentLocation != null) MarkerLayer(markers: [Marker(point: _currentLocation!, child: const Icon(Icons.my_location, color: Colors.blue, size: 25))]),
                  ],
                );
              }
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            Positioned(
              bottom: 10, left: 15, right: 80,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                child: TextField(
                  decoration: const InputDecoration(hintText: "ძებნა...", border: InputBorder.none, icon: Icon(Icons.search, color: Colors.indigo)),
                  onChanged: (val) {
                    _searchQuery = val.toLowerCase();
                    _filterMarkers();
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 10, right: 15,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _mapFab(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1), "zoom_in"),
                  const SizedBox(height: 8),
                  _mapFab(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1), "zoom_out"),
                  const SizedBox(height: 8),
                  _mapFab(Icons.center_focus_strong, () {
                    if (_markers.isNotEmpty) {
                      final points = _markers.map((m) => m.point).toList();
                      if (points.length == 1) {
                        _mapController.move(points.first, 18);
                      } else {
                        final bounds = LatLngBounds.fromPoints(points);
                        _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)));
                      }
                    } else {
                      _mapController.move(_initialLocation, 15);
                    }
                  }, "focus", color: Colors.orange, iconColor: Colors.white),
                  const SizedBox(height: 8),
                  _mapFab(Icons.gps_fixed, () async {
                    await _determinePosition();
                    if (_currentLocation != null) _mapController.move(_currentLocation!, 17);
                  }, "gps", color: Colors.indigo, iconColor: Colors.white),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final double systemBottom = MediaQuery.of(context).systemGestureInsets.bottom;
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo),
            child: Center(child: Text('მენიუ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: systemBottom + 20),
              children: [
                ExpansionTile(
                  leading: const Icon(Icons.filter_list, color: Colors.indigo),
                  title: const Text('შრეების მართვა'),
                  initiallyExpanded: true,
                  children: _categoryGroups.keys.map((group) {
                    return CheckboxListTile(
                      title: Text(group),
                      value: _enabledGroups.contains(group),
                      onChanged: (val) {
                        setState(() {
                          if (val!) _enabledGroups.add(group); else _enabledGroups.remove(group);
                          _filterMarkers();
                        });
                      },
                    );
                  }).toList(),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.indigo),
                  title: Text('აპლიკაციის შესახებ'),
                  subtitle: Text('ივერთუბნის რუკა v1.0\nავტორი: ივერთუბნის გუნდი\nგანახლებულია: 2024'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapFab(IconData icon, VoidCallback onPressed, String tag, {Color color = Colors.white, Color iconColor = Colors.indigo}) {
    return FloatingActionButton(mini: true, heroTag: tag, backgroundColor: color, onPressed: onPressed, child: Icon(icon, color: iconColor, size: 20));
  }
}

class _MarkerStyle {
  final IconData icon;
  final Color color;
  _MarkerStyle(this.icon, this.color);
}
