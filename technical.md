# 🧱 Architecture

The project now follows a **layered structure**:

```
lib/
├── map_screen/
│   ├── widgets/
│   ├── screens/
├── utils/
├── services/
```

### Layers:

* **UI Layer**

    * Widgets
    * Screens
* **Logic Layer**

    * Services (data, location, marker processing)
* **Utility Layer**

    * Shared helpers and models (e.g. enums, styles)

---

# ✅ Key Improvements

## 🧠 Clean Architecture

* Moved business logic out of UI
* Introduced dedicated services:

    * `MapDataService`
    * `LocationService`
    * `MapActionsService`
    * `MarkerService`
    * `AppLauncherService` (singleton)

---

## 🧩 Enum-Based Categories

Replaced string-based category system with:

```dart
enum MapCategory
```

Each category now contains:

* label
* subcategories
* marker style (icon + color)

### Benefits:

* Type safety
* Centralized configuration
* No duplicated logic
* Easier scalability

---

## 🔍 Improved Filtering System

* Extracted filtering logic into `MarkerService`
* Removed string comparisons
* Introduced enum-based filtering

---

## 🔗 External Actions Refactor

* Moved URL launching logic into `AppLauncherService`
* Implemented singleton pattern

---

## 🧼 State & Input Improvements

* Removed unnecessary `_searchQuery`
* Used `TextEditingController` directly
* Reduced duplicated state

---

## 📁 Better Project Structure

* Separated widgets, services, and utilities
* Improved readability and maintainability

---

# ⚠️ Issues Fixed

* Deprecated API usage (`withOpacity`)
* Unused imports
* Redundant `.toList()`
* Overcomplicated platform checks
* Missing controller disposal
* Poor separation of concerns

---

## 🚀 Additional Improvements

### 🔍 Add Search Debounce

#### ❗ Problem

Currently, filtering runs on every keystroke, which may cause unnecessary rebuilds and performance issues.

#### ✅ Solution

Introduce a debounce mechanism to delay execution until the user stops typing.

#### 🧩 Implementation

```dart
Timer? _debounce;

void _onSearchChanged(String value) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();

  _debounce = Timer(const Duration(milliseconds: 300), () {
    _filterMarkers();
  });
}
```

Use it in your text field:

```dart
onChanged: _onSearchChanged,
```

#### 📚 Documentation

* https://api.dart.dev/stable/dart-async/Timer-class.html

---

### 🌙 Add Dark Mode

#### ❗ Goal

Support both light and dark themes automatically or via user selection.

#### ✅ Basic Setup

```dart
MaterialApp(
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: ThemeMode.system, // or ThemeMode.dark / light
)
```

#### 🎨 Custom Theme Example

```dart
final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.indigo,
  scaffoldBackgroundColor: Colors.black,
);
```

#### 🗺 Map Styling (for flutter_map)

```dart
TileLayer(
  urlTemplate: isDarkMode
      ? 'https://tiles.stadiamaps.com/tiles/alidade_dark/{z}/{x}/{y}.png'
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
)
```

#### 📚 Documentation

* https://docs.flutter.dev/cookbook/design/themes

---

### 🌍 Add Localization (i18n)

#### ❗ Goal

Support multiple languages (e.g., Georgian 🇬🇪 and English 🇬🇧)

---

#### ✅ Step 1: Enable localization

```yaml
flutter:
  generate: true
```

---

#### ✅ Step 2: Add dependencies

```bash
flutter pub add flutter_localizations
```

---

#### ✅ Step 3: Configure MaterialApp

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('ka'),
  ],
)
```

---

#### ✅ Step 4: Create translation files

Create folder:

```
lib/l10n/
```

Add file: `app_en.arb`

```json
{
  "menu": "Menu",
  "filters": "Filters"
}
```

Add file: `app_ka.arb`

```json
{
  "menu": "მენიუ",
  "filters": "ფილტრები"
}
```

---

#### ✅ Step 5: Use localized strings

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.menu)
```

---

#### 📚 Documentation

* https://docs.flutter.dev/development/accessibility-and-localization/internationalization


