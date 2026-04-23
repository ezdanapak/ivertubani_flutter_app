import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class MapDataService {
  Future<List<Map<String, dynamic>>> loadData() async {
    if (kIsWeb) {
      final response = await rootBundle.loadString('assets/data.geojson');
      final data = json.decode(response);

      final features = data['features'] as List;

      return features.map((f) {
        final props = Map<String, dynamic>.from(f['properties']);
        final geometry = f['geometry'];

        if (geometry != null && geometry['type'] == 'Point') {
          final coords = geometry['coordinates'];
          props['long'] = coords[0];
          props['lat'] = coords[1];
        }

        return props;
      }).toList();
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'data.gpkg');

    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }

    final data = await rootBundle.load('assets/data.gpkg');
    await file.writeAsBytes(data.buffer.asUint8List());

    final db = await openDatabase(path);
    final result = await db.query('poi');
    await db.close();

    return result;
  }
}