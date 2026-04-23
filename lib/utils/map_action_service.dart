import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapActionsService {
  final MapController controller;

  MapActionsService(this.controller);

  void zoomIn() {
    controller.move(controller.camera.center, controller.camera.zoom + 1);
  }

  void zoomOut() {
    controller.move(controller.camera.center, controller.camera.zoom - 1);
  }

  void focus({required List<Marker> markers, required LatLng initialLocation}) {
    if (markers.isNotEmpty) {
      final points = markers.map((m) => m.point).toList();

      if (points.length == 1) {
        controller.move(points.first, 18);
      } else {
        final bounds = LatLngBounds.fromPoints(points);

        controller.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)),
        );
      }
    } else {
      controller.move(initialLocation, 15);
    }
  }

  void goToLocation(LatLng location) {
    controller.move(location, 17);
  }
}
