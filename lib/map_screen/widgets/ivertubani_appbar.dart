import 'package:flutter/material.dart';

class IvertubaniAppBar extends StatelessWidget implements PreferredSizeWidget {
  const IvertubaniAppBar({
    super.key,
    required this.onAddLocation,
    required this.onRefresh,
  });

  final VoidCallback onAddLocation;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'ივერთუბანი',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.indigo,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_location_alt, color: Colors.white),
          onPressed: onAddLocation,
          tooltip: 'წერტილის დამატება',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: onRefresh,
          tooltip: 'განახლება',
        ),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'მენიუ',
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
