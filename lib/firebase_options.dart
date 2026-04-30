// Generated manually from google-services.json + Firebase Console.
// To regenerate: flutterfire configure (requires flutterfire_cli)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Web ─────────────────────────────────────────────────────────────────────
  // წყარო: Firebase Console → Project settings → Your apps → Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDmR3bhwj4cWr0Lh1PWawPoD8uK0rK6Fy0',
    appId: '1:828260933495:web:afea3b58beaa8eee8b8b72',
    messagingSenderId: '828260933495',
    projectId: 'ivertubani-6af0d',
    authDomain: 'ivertubani-6af0d.firebaseapp.com',
    storageBucket: 'ivertubani-6af0d.firebasestorage.app',
    measurementId: 'G-CVZZDXMJCL',
  );

  // ── Android ─────────────────────────────────────────────────────────────────
  // წყარო: android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCRMPN4-pp2__KPay3AKUJWKE1NBgFV_vU',
    appId: '1:828260933495:android:5fa8057ab4af7c258b8b72',
    messagingSenderId: '828260933495',
    projectId: 'ivertubani-6af0d',
    storageBucket: 'ivertubani-6af0d.firebasestorage.app',
  );
}
