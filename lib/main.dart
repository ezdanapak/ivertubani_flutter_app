import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'utils/locale_service.dart';
import 'utils/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase — Analytics (Android + Web)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load saved theme and locale before the first frame.
  await ThemeService.instance.init();
  await LocaleService.instance.init();

  if (!kIsWeb && Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}
