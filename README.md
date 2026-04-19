# ივერთუბნის რუკა (Ivertubani Map)

ინტერაქტიული რუკის აპლიკაცია, რომელიც შექმნილია **Flutter**-ის გამოყენებით. აპლიკაცია საშუალებას გაძლევთ დაათვალიეროთ OpenStreetMap და იმუშაოთ ლოკალურ გეომონაცემებთან (GeoPackage).

## 🚀 ფუნქციები (Features)

- **OSM ინტეგრაცია:** დინამიური რუკა OpenStreetMap-ის ფილების (Tiles) გამოყენებით.
- **GeoPackage (GPKG) მხარდაჭერა:** მონაცემების წაკითხვა ლოკალური SQLite/GPKG ბაზიდან.
- **GPS ლოკაცია:** მომხმარებლის რეალურ დროში定位 (Real-time positioning) და რუკაზე ჩვენება.
- **შრეების კონტროლი:** წერტილოვანი მონაცემების (POI) ჩართვა/გამორთვა.
- **ატრიბუტების ნახვა:** წერტილზე დაჭერისას ინფორმაციის გამოტანა Bottom Sheet-ის სახით.
- **რუკის კონტროლი:** Zoom In/Out, GPS ცენტრირება და წერტილებზე ავტომატური ფოკუსირება.

## 🛠 გამოყენებული ტექნოლოგიები (Tech Stack)

- **Framework:** [Flutter](https://flutter.dev)
- **Mapping:** [flutter_map](https://pub.dev/packages/flutter_map)
- **Database:** [sqflite](https://pub.dev/packages/sqflite) (GeoPackage parsing)
- **Location:** [geolocator](https://pub.dev/packages/geolocator)
- **Coordinate Systems:** WGS 84 (EPSG:4326)

## 📦 დაყენება (Setup)

1. დარწმუნდით, რომ გაქვთ Flutter დაინსტალირებული.
2. ჩამოტვირთეთ პროექტი:
   ```bash
   git clone https://github.com/your-username/ivertubani.git
   ```
3. დააინსტალირეთ დამოკიდებულებები:
   ```bash
   flutter pub get
   ```
4. მოათავსეთ თქვენი `data.gpkg` ფაილი `assets/` საქაღალდეში.
5. გაუშვით აპლიკაცია:
   ```bash
   flutter run
   ```

## 📝 შენიშვნა
აპლიკაცია მორგებულია სპეციალურად ივერთუბნის ტერიტორიის კოორდინატებზე, თუმცა მისი გამოყენება შესაძლებელია ნებისმიერი სხვა GeoPackage მონაცემებისთვისაც.
