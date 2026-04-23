import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  Future<LatLng?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("GPS Error: $e");
      return null;
    }
  }
}