import 'package:flutter/material.dart';

class MapFab extends StatelessWidget {
  const MapFab({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.heroTag,
    this.backgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final Future<void> Function() onPressed;
  final String heroTag;

  // null → theme-დან ავტომატურად.
  // კონკრეტული ფერი (მაგ. focus ღილაკი orange) → override.
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.surface;
    final ic = iconColor ?? scheme.primary;

    return FloatingActionButton(
      mini: true,
      heroTag: heroTag,
      backgroundColor: bg,
      onPressed: onPressed,
      child: Icon(icon, color: ic, size: 20),
    );
  }
}
