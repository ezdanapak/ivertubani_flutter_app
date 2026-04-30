// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Georgian (`ka`).
class AppLocalizationsKa extends AppLocalizations {
  AppLocalizationsKa([String locale = 'ka']) : super(locale);

  @override
  String get appTitle => 'ივერთუბანი';

  @override
  String get addLocation => 'წერტილის დამატება';

  @override
  String get refresh => 'განახლება';

  @override
  String get menu => 'მენიუ';

  @override
  String get drawerHeader => 'ივერთუბანი';

  @override
  String get darkMode => 'მუქი რეჟიმი';

  @override
  String get lightMode => 'ღია რეჟიმი';

  @override
  String get layerManagement => 'შრეების მართვა';

  @override
  String get closeDrawer => 'დახურვა';

  @override
  String get aboutApp => 'აპლიკაციის შესახებ';

  @override
  String get aboutText => 'ივერთუბნის რუკა v1.0\nგანახლებულია: 22.04.2026';

  @override
  String get author => 'ავტორი: ezdanapak ➔';

  @override
  String get language => 'ენა';

  @override
  String get languageGeorgian => '🇬🇪 ქართული';

  @override
  String get languageEnglish => '🇬🇧 English';

  @override
  String get searchHint => 'ძებნა...';

  @override
  String get loadError => 'მონაცემების ჩატვირთვა ვერ მოხერხდა';

  @override
  String get linkError => 'ვერ მოხერხდა ბმულის გახსნა';

  @override
  String get retry => 'ხელახლა';

  @override
  String get noResults => 'ვერ მოიძებნა';

  @override
  String get copiedLabel => 'დაკოპირდა';

  @override
  String copied(String text) {
    return 'დაკოპირდა: $text';
  }

  @override
  String get viewOnGoogleMaps => 'იხილეთ Google Maps-ზე ➔';

  @override
  String get categoryEducation => 'განათლება';

  @override
  String get categoryTransport => 'ტრანსპორტი';

  @override
  String get categoryFood => 'კვება';

  @override
  String get categoryHealth => 'ჯანმრთელობა';

  @override
  String get categoryBeauty => 'სილამაზე';

  @override
  String get categoryLeisure => 'დასვენება';

  @override
  String get categoryReligion => 'რელიგია';

  @override
  String get categoryServices => 'სერვისები';

  @override
  String get categoryForSale => 'იყიდება';

  @override
  String get categoryOther => 'სხვა';
}
