// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ivertubani';

  @override
  String get addLocation => 'Add location';

  @override
  String get refresh => 'Refresh';

  @override
  String get menu => 'Menu';

  @override
  String get drawerHeader => 'Ivertubani';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get lightMode => 'Light mode';

  @override
  String get layerManagement => 'Manage layers';

  @override
  String get closeDrawer => 'Close';

  @override
  String get aboutApp => 'About';

  @override
  String get aboutText => 'Ivertubani Map v1.0\nUpdated: 22.04.2026';

  @override
  String get author => 'Author: ezdanapak ➔';

  @override
  String get language => 'Language';

  @override
  String get languageGeorgian => '🇬🇪 ქართული';

  @override
  String get languageEnglish => '🇬🇧 English';

  @override
  String get searchHint => 'Search...';

  @override
  String get loadError => 'Failed to load data';

  @override
  String get linkError => 'Could not open the link';

  @override
  String get retry => 'Retry';

  @override
  String get noResults => 'No results found';

  @override
  String get copiedLabel => 'Copied';

  @override
  String copied(String text) {
    return 'Copied: $text';
  }

  @override
  String get viewOnGoogleMaps => 'View on Google Maps ➔';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryFood => 'Food & Drink';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryBeauty => 'Beauty';

  @override
  String get categoryLeisure => 'Leisure';

  @override
  String get categoryReligion => 'Religion';

  @override
  String get categoryServices => 'Services';

  @override
  String get categoryForSale => 'For Sale';

  @override
  String get categoryOther => 'Other';
}
