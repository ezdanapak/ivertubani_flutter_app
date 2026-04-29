# ─── Flutter ──────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ─── Kotlin ───────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

# ─── Dio / OkHttp ─────────────────────────────────────────────────────────────
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ─── sqflite ──────────────────────────────────────────────────────────────────
-keep class com.tekartik.sqflite.** { *; }

# ─── url_launcher ─────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }

# ─── geolocator ───────────────────────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }

# ─── General: keep native methods & annotations ───────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepclassmembers class * {
    native <methods>;
}
