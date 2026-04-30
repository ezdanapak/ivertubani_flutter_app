import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the in-app review prompt.
///
/// აქტიურდება მე-5 სესიის შემდეგ, შემდეგ ყოველ 30 სესიაზე ერთხელ.
/// სესია = აპლიკაციის გახსნა (logMapSessionStart-თან ერთად).
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const _keySessionCount = 'session_count';
  static const _firstThreshold  = 5;
  static const _repeatEvery     = 30;

  /// გამოიძახება main thread-ზე ყოველ სესიაზე.
  /// [request] — review dialog-ს გახსნა.
  Future<void> onSessionStart() async {
    // Web-ზე in_app_review არ მუშაობს.
    if (kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_keySessionCount) ?? 0) + 1;
      await prefs.setInt(_keySessionCount, count);

      final shouldRequest =
          count == _firstThreshold ||
          (count > _firstThreshold && (count - _firstThreshold) % _repeatEvery == 0);

      if (!shouldRequest) return;

      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (e) {
      debugPrint('[ReviewService] error: $e');
    }
  }
}
