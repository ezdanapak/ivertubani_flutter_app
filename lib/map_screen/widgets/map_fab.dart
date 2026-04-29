import 'package:flutter/material.dart';

class MapFab extends StatelessWidget {
  const MapFab({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.heroTag,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.indigo,
  });

  final IconData icon;

  // Future<void> Function() — handles both sync and async callbacks correctly.
  // Sync callbacks: () { ... } is assignable (Dart return-type covariance).
  // Async callbacks: Future is properly awaited inside FloatingActionButton.
  final Future<void> Function() onPressed;

  final String heroTag;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      heroTag: heroTag,
      backgroundColor: backgroundColor,
      onPressed: onPressed,
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}
