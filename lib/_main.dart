import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'widgets/initialize_app_future.dart';
import 'widgets/my_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const AppInitializationFutureBuilder(
      initialize: _initializeComponents,
      app: MyApp(),
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
    initializeDateFormatting(Platform.localeName),
  ]);
}
