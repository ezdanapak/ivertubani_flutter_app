import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  /// Returns the current [LatLng] or null if unavailable.
  ///
  /// Permission flow:
  ///  1. Service disabled  → null (მომხმარებელი GPS-ს არ იყენებს)
  ///  2. denied            → request; if still denied → null
  ///  3. deniedForever     → opens app settings (ერთადერთი გამოსავალი)
  ///  4. granted / always  → position
  Future<LatLng?> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    // deniedForever: Android/iOS don't allow runtime request again.
    // openAppSettings() — მომხმარებელი პარამეტრებში გაიყვანება.
    if (permission == LocationPermission.deniedForever) {
      debugPrint('LocationService: permission deniedForever — opening settings');
      await Geolocator.openAppSettings();
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('LocationService error: $e');
      return null;
    }
  }
}
