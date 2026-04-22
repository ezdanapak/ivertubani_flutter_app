# 🛠 დეველოპერული გზამკვლევი (Technical Documentation)

ეს დოკუმენტი განკუთვნილია პროექტის ტექნიკური მხარისთვის. აქ მოცემულია ყველა საჭირო ხელსაწყო, ბრძანება და ინსტალაციის პროცესი, რომელიც პროექტის ასამუშავებლად იქნა გამოყენებული.

---

## 💻 სისტემური მოთხოვნები (Environment Setup)

პროექტის სხვა კომპიუტერზე გასაშვებად საჭიროა შემდეგი პროგრამების ინსტალაცია:

### 1. Flutter SDK
*   **ინსტალაცია:** [flutter.dev](https://docs.flutter.dev/get-started/install/windows)
*   **შემოწმება:** ტერმინალში ჩაწერეთ `flutter doctor`. ის გეტყვით, ყველაფერი სწორად არის თუ არა დაინსტალირებული.

### 2. Git
*   **ინსტალაცია:** [git-scm.com](https://git-scm.com/) - საჭიროა ვერსიების კონტროლისა და GitHub-ზე კოდის ასატვირთად.

### 3. Visual Studio (Windows Build-ისთვის)
*   Windows დესკტოპ აპლიკაციის ასაწყობად საჭიროა **Visual Studio 2022**.
*   ინსტალაციისას აუცილებლად მონიშნეთ ვორქლოუ: **"Desktop development with C++"**.

### 4. NuGet Package Manager
*   საჭიროა Windows-ის ბიბლიოთეკების სამართავად.
*   თუ ტერმინალი ითხოვს, გადმოწერეთ `nuget.exe` [აქედან](https://www.nuget.org/downloads) და დაამატეთ სისტემის Path-ში.

---

## 📦 გამოყენებული Flutter პაკეტები

პროექტის `pubspec.yaml`-ში დამატებულია შემდეგი მნიშვნელოვანი ბიბლიოთეკები:

*   **flutter_map:** რუკის ძირითადი ძრავა.
*   **latlong2:** კოორდინატების (Latitude/Longitude) მართვისთვის.
*   **sqflite:** SQLite ბაზასთან მუშაობისთვის (Mobile).
*   **sqflite_common_ffi:** SQLite-ის მხარდაჭერა Windows-ისთვის.
*   **url_launcher:** გარე ბმულების (Google Maps, Google Forms) გასახსნელად.
*   **geolocator:** მომხმარებლის GPS ადგილმდებარეობის დასადგენად.
*   **flutter_map_cache:** რუკის ფილების (tiles) ქეშირებისთვის, რათა აპლიკაციამ ოფლაინშიც იმუშაოს.

---

## 🛠 ძირითადი ბრძანებები (Terminal Commands)

### პროექტის მომზადება:
```powershell
# პაკეტების ჩამოტვირთვა
flutter pub get

# ძველი ფაილების და ქეშის გასუფთავება
flutter clean

# Windows და Web მხარდაჭერის დამატება პროექტში
flutter create --platforms=windows,web .
```

### აპლიკაციის გაშვება:
```powershell
# Android-ზე
flutter run -d android

# Windows-ზე
flutter run -d windows

# Chrome-ში
flutter run -d chrome
```

---

## 🌐 Web Deployment (GitHub Pages & Custom Domain)

პროექტი ქვეყნდება **https://ivertubani.qgis.ge**-ზე.

### გამოყენებული ხელსაწყო: **Peanut**
ეს პაკეტი ავტომატურად აწყობს ვებ-ვერსიას და ტვირთავს `gh-pages` ბრანჩზე.

1.  **Peanut-ის გააქტიურება:**
    `dart pub global activate peanut`
2.  **ბილდის გაკეთება:**
    `dart pub global run peanut`
3.  **ატვირთვა GitHub-ზე:**
    `git push origin gh-pages --force`

### Custom Domain კონფიგურაცია:
*   **web/CNAME:** ფაილი, რომელიც აფიქსირებს `ivertubani.qgis.ge` დომენს.
*   **web/index.html:** შეიცავს `<base href="/">` ჩანაწერს.
*   **DNS ჩანაწერი:** დომენის პანელში დამატებულია `CNAME` ტიპის ჩანაწერი: `ivertubani` -> `ezdanapak.github.io`.

---

## 🗺️ მონაცემთა მართვა (GIS Workflow)

1.  **QGIS:** გამოიყენება წერტილების (POI) დასამატებლად და დასამუშავებლად.
2.  **Geopackage (.gpkg):** ძირითადი ბაზა Android-ისთვის და Windows-ისთვის.
3.  **GeoJSON (.geojson):** ექსპორტირებული ფაილი Web-ვერსიისთვის (რადგან ბრაუზერი პირდაპირ .gpkg-ს ვერ კითხულობს).

---

## ⚠️ ხშირი შეცდომები და გადაჭრა

*   **Error: databaseFactory not initialized:** ჩნდება Windows-ზე. გამოსავალი: `main()` ფუნქციაში `sqfliteFfiInit()`-ის გამოძახება.
*   **URL Launcher 404/Not working (Android):** გამოსავალი: `AndroidManifest.xml`-ში `<queries>` ტეგის დამატება.
*   **Web 404 on Assets:** გამოსავალი: `pubspec.yaml`-ში ფაილების რეგისტრაცია და `flutter pub get`.

---
© 2026 ezdanapak. ყველა უფლება დაცულია.
