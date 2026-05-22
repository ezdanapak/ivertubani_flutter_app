import 'package:flutter/material.dart';
import 'package:ivertubani/generated/app_localizations.dart';
import 'package:lottie/lottie.dart';

class IvertubaniAppBar extends StatelessWidget implements PreferredSizeWidget {
  const IvertubaniAppBar({
    super.key,
    required this.onAddLocation,
  });

  final VoidCallback onAddLocation;

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
          icon: Lottie.asset(
            'assets/animations/add_location.json',
            width: 32,
            height: 32,
            repeat: true,
            fit: BoxFit.contain,
          ),
          onPressed: onAddLocation,
          tooltip: l10n.addLocation,
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
