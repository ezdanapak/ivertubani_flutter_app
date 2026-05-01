import 'package:flutter/material.dart';

class MapFab extends StatelessWidget {
  const MapFab({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.heroTag,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
  });

  final IconData icon;
  final Future<void> Function() onPressed;
  final String heroTag;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.surface;
    final ic = iconColor ?? scheme.primary;

    final fab = FloatingActionButton(
      mini: true,
      heroTag: heroTag,
      backgroundColor: bg,
      onPressed: onPressed,
      child: Icon(icon, color: ic, size: 20),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: fab);
    }
    return fab;
  }
}
