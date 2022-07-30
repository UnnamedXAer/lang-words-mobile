import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lang_words/widgets/error_text.dart';
import 'package:lang_words/widgets/ui/spinner.dart';
import 'firebase_options.dart';

import 'package:lang_words/pages/auth/forgot_password_page.dart';
import 'package:lang_words/pages/auth/forgot_password_success_page.dart';
import 'package:lang_words/pages/not_found_page.dart';
import 'package:lang_words/routes/routes.dart';

import 'constants/colors.dart';
import 'pages/auth/auth_page.dart';
import 'widgets/inherited/auth_state.dart';
import 'widgets/layout/auth_state_switch.dart';
import 'widgets/layout/logged_in_layout.dart';
import 'widgets/layout/main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppInitializationFutureBuilder(
      app: AuthState(
        child: MaterialApp(
          title: 'Lang Words',
          color: AppColors.primary,
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'OpenSans',
            scaffoldBackgroundColor: AppColors.bg,
            backgroundColor: AppColors.bg,
            dialogTheme: const DialogTheme(
              backgroundColor: AppColors.bgDialog,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.zero,
                ),
              ),
            ),
            colorScheme: ColorScheme(
              brightness: Brightness.dark,
              surface: AppColors.bgCard,
              onSurface: AppColors.text,
              background: AppColors.bg,
              onBackground: AppColors.text,
              error: AppColors.error,
              onError: AppColors.textLight,
              primary: AppColors.primary,
              onPrimary: AppColors.textLight,
              secondary: AppColors.secondary,
              onSecondary: AppColors.bg,
              outline: AppColors.primary,

              /////////// dummy colors
              tertiary: Colors.yellow.shade400,
              shadow: Colors.yellow.shade400,
              surfaceTint: Colors.yellow.shade400,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.bgHeader,
            ),
            textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: AppColors.text,
                  displayColor: AppColors.text,
                ),
            // textSelectionTheme: TextSelectionThemeData(),
            inputDecorationTheme: InputDecorationTheme(
              fillColor: AppColors.bgInput,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
              border: InputBorder.none,
              filled: true,
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.borderInputFocus,
                  width: 5,
                ),
                borderRadius: BorderRadius.zero,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.borderInputFocus.withOpacity(0.05),
                  width: 5,
                ),
                borderRadius: BorderRadius.zero,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.error.withOpacity(0.4),
                  width: 5,
                ),
                borderRadius: BorderRadius.zero,
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.error.withOpacity(0.2),
                  width: 5,
                ),
                borderRadius: BorderRadius.zero,
              ),
              disabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  width: 5,
                  style: BorderStyle.none,
                ),
                borderRadius: BorderRadius.zero,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(AppColors.border),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(AppColors.border),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                ),
              ),
            ),
          ),
          home: const AuthStateSwitch(),
          routes: {
            RoutesUtil.routeAuth: (context) => const MainLayout(
                  page: AuthPage(),
                ),
            RoutesUtil.routeAuthForgotPassword: (context) => const MainLayout(
                  page: ForgotPasswordPage(),
                ),
            RoutesUtil.routeAuthForgotPasswordSuccess: (context) =>
                const MainLayout(
                  page: ForgotPasswordSuccessPage(),
                ),
            RoutesUtil.routePrefixLogged: (context) => const MainLayout(
                  page: LoggedInLayout(),
                ),
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute<dynamic>(
              builder: (_) => const MainLayout(
                page: NotFoundPage(),
              ),
              settings: settings,
            );
          },
        ),
      ),
    );
  }
}

class AppInitializationFutureBuilder extends StatefulWidget {
  const AppInitializationFutureBuilder({required this.app, Key? key})
      : super(key: key);

  final Widget app;

  @override
  State<AppInitializationFutureBuilder> createState() =>
      _AppInitializationFutureBuilderState();
}

class _AppInitializationFutureBuilderState
    extends State<AppInitializationFutureBuilder> {
  late final Future _initialization;

  @override
  void initState() {
    super.initState();
    // keep initialization Future object in a variable to
    // prevent calling it on every hot reload
    // which causes lost state in the widget tree below this widget;
    _initialization = _initializeComponents();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: FutureBuilder(
        future: _initialization,
        builder: (context, initializationSnapshot) {
          log('🔮 FutureBuilder ${initializationSnapshot.connectionState}');

          if (initializationSnapshot.hasError) {
            return Center(
              child: Material(
                type: MaterialType.transparency,
                child: ErrorText(
                  'Sorry, unable to initialize app due to:\n${initializationSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (initializationSnapshot.connectionState ==
              ConnectionState.waiting) {
            // TODO: add some logo ect.
            return const Center(
              child: Spinner(
                size: SpinnerSize.large,
              ),
            );
          } else {
            return widget.app;
          }
        },
      ),
    );
  }
}
