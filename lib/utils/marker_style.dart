import 'package:flutter/material.dart';
import 'package:ivertubani/generated/app_localizations.dart';

enum MapCategory {
  education(
    label: 'განათლება',
    subCategories: ['განათლება', 'სკოლა', 'ბაღი', 'მასწავლებელი'],
    style: MarkerStyle(Icons.school, Colors.purple),
  ),
  transport(
    label: 'ტრანსპორტი',
    subCategories: ['ტრანსპორტი', 'ავტომობილი', 'გასამართი'],
    style: MarkerStyle(Icons.local_gas_station, Colors.orangeAccent),
  ),
  food(
    label: 'კვება',
    subCategories: ['კვება', 'მარკეტი', 'მაღაზია', 'რესტორანი', 'კაფე'],
    style: MarkerStyle(Icons.restaurant, Colors.red),
  ),
  health(
    label: 'ჯანმრთელობა',
    subCategories: ['ჯანმრთელობა', 'აფთიაქი'],
    style: MarkerStyle(Icons.local_pharmacy, Colors.green),
  ),
  beauty(
    label: 'სილამაზე',
    subCategories: ['სილამაზე', 'სალონი'],
    style: MarkerStyle(Icons.face, Colors.pinkAccent),
  ),
  leisure(
    label: 'დასვენება',
    subCategories: ['დასვენება', 'პარკი'],
    style: MarkerStyle(Icons.park, Colors.lightGreen),
  ),
  religion(
    label: 'რელიგია',
    subCategories: ['რელიგია', 'ეკლესია'],
    style: MarkerStyle(Icons.church, Colors.brown),
  ),
  services(
    label: 'სერვისები',
    subCategories: ['სერვისები'],
    style: MarkerStyle(Icons.miscellaneous_services, Colors.blueGrey),
  ),
  forSale(
    label: 'იყიდება',
    subCategories: ['შაბლონი', 'იყიდება'],
    style: MarkerStyle(Icons.sell, Colors.redAccent),
  ),
  other(
    label: 'სხვა',
    subCategories: ['სხვა'],
    style: MarkerStyle(Icons.location_on, Colors.grey),
  );

  const MapCategory({
    required this.label,
    required this.subCategories,
    required this.style,
  });

  final String label;
  final List<String> subCategories;
  final MarkerStyle style;

  static MapCategory fromRaw(String type, String category) {
    final t = type.toLowerCase();
    final c = category.toLowerCase();

    for (final cat in MapCategory.values) {
      if (cat.subCategories.any((s) => t.contains(s) || c.contains(s))) {
        return cat;
      }
    }

    return MapCategory.other;
  }
}

class MarkerStyle {
  final IconData icon;
  final Color color;

  const MarkerStyle(this.icon, this.color);
}

/// Returns the localized label for a [MapCategory].
/// Use this instead of [MapCategory.label] (which is the Georgian default).
extension MapCategoryL10n on MapCategory {
  String labelFor(AppLocalizations l10n) {
    switch (this) {
      case MapCategory.education:
        return l10n.categoryEducation;
      case MapCategory.transport:
        return l10n.categoryTransport;
      case MapCategory.food:
        return l10n.categoryFood;
      case MapCategory.health:
        return l10n.categoryHealth;
      case MapCategory.beauty:
        return l10n.categoryBeauty;
      case MapCategory.leisure:
        return l10n.categoryLeisure;
      case MapCategory.religion:
        return l10n.categoryReligion;
      case MapCategory.services:
        return l10n.categoryServices;
      case MapCategory.forSale:
        return l10n.categoryForSale;
      case MapCategory.other:
        return l10n.categoryOther;
    }
  }
}
