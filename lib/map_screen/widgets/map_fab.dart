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
  final VoidCallback onPressed;
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
      child: Icon(
        icon,
        color: iconColor,
        size: 20,
      ),
    );
  }
}