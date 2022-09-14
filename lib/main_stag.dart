import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lang_words/app_config.dart';
import 'package:lang_words/firebase_options_stg.dart';
import 'package:lang_words/services/words_local_service.dart';
import 'package:lang_words/widgets/initialize_app_future.dart';
import 'package:lang_words/widgets/my_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const AppConfig(
      env: Environment.stage,
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
