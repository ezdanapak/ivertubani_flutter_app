import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'utils/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved theme before the first frame.
  await ThemeService.instance.init();

  if (!kIsWeb && Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}
