import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lang_words/app_config.dart';
import 'package:lang_words/firebase_options_dev.dart';
import 'package:lang_words/services/object_box_service.dart';
import 'package:lang_words/widgets/initialize_app_future.dart';
import 'package:lang_words/widgets/my_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const AppConfig(
      env: Environment.dev,
      child: AppInitializationFutureBuilder(
        initialize: _initializeComponents,
        app: MyApp(),
      ),
    ),
  );
}

Future<List<void>> _initializeComponents() {
  return Future.wait([
    () {
      log('initialize firebase');
      return Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }(),
    ObjectBoxService.initialize(),
    initializeDateFormatting(Platform.localeName),
  ]);
}
