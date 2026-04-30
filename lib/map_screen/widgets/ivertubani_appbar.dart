import 'package:flutter/material.dart';
import 'package:ivertubani/generated/app_localizations.dart';

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
    // ფერები ThemeData.appBarTheme-იდან მოდის (app.dart).
    // hardcoded color-ი აქ არ უნდა იყოს — dark mode-ს გადაფარავდა.
    final l10n = AppLocalizations.of(context);
    return AppBar(
      title: Text(
        l10n.appTitle,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_location_alt),
          onPressed: onAddLocation,
          tooltip: l10n.addLocation,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: l10n.refresh,
        ),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: l10n.menu,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
