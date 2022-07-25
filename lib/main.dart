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
import 'constants/sizes.dart';
import 'pages/auth/auth_page.dart';
import 'widgets/inherited/auth_state.dart';
import 'widgets/layout/app_drawer.dart';
import 'widgets/layout/logged_in_layout.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeComponents();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: ColoredBox(
        color: AppColors.bg,
        child: FutureBuilder(
          future: _initialization,
          builder: (context, initializationSnapshot) {
            log('FutureBuilder ${initializationSnapshot.connectionState}');

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
              return const AuthState(child: _AuthLoggedSwitch());
            }
          },
        ),
      ),
      // initialRoute: RoutesUtil.routeAuth,
      routes: {
        RoutesUtil.routeAuth: (context) => const _MainLayout(
              page: AuthPage(),
            ),
        RoutesUtil.routeAuthForgotPassword: (context) => const _MainLayout(
              page: ForgotPasswordPage(),
            ),
        RoutesUtil.routeAuthForgotPasswordSuccess: (context) =>
            const _MainLayout(
              page: ForgotPasswordSuccessPage(),
            ),
        RoutesUtil.routePrefixLogged: (context) => const _MainLayout(
              page: LoggedInLayout(),
            ),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute<dynamic>(
          builder: (_) => const _MainLayout(
            page: NotFoundPage(),
          ),
          settings: settings,
        );
      },
    );
  }
}

class _AuthLoggedSwitch extends StatelessWidget {
  const _AuthLoggedSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authInfo = AuthInfo.of(context);

    Widget page;

    if (authInfo.isLoggedIn == true) {
      page = const _MainLayout(
        key: ValueKey('LoggedIn pages'),
        page: LoggedInLayout(),
      );
    } else if (authInfo.isLoggedIn == false) {
      page = const _MainLayout(
        key: ValueKey('Auth pages'),
        page: AuthPage(),
      );
    } else {
      page = const Center(
        key: ValueKey('spinner - auth'),
        child: Spinner(
          size: SpinnerSize.large,
        ),
      );
    }

    const Duration switchDuration = Duration(milliseconds: 300);
    log('!!! _AuthLoggedSwitch - is logged: ${authInfo.isLoggedIn}, about to switch to: ${page.key.toString()}');

    return AnimatedSwitcher(
      duration: switchDuration,
      reverseDuration: switchDuration,
      child: page,
      transitionBuilder: (child, animation) {
        log('AnimatedSwitcher ${animation.value}, ${child.key}');
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation.drive(
              Tween(begin: 0.85, end: 1),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _MainLayout extends StatelessWidget {
  const _MainLayout({
    required Widget page,
    Key? key,
  })  : _page = page,
        super(key: key);

  final Widget _page;

  @override
  Widget build(BuildContext context) {
    final bigScreen = MediaQuery.of(context).size.width >= Sizes.maxWidth;
    final double margin = bigScreen ? 19 : 0;

    return GestureDetector(
      onTap: () {
        AppDrawer.navKey.currentState?.toggle(false);
      },
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints:
                  const BoxConstraints(minWidth: 330, maxWidth: Sizes.maxWidth),
              margin: EdgeInsets.all(margin),
              child: _page,
            ),
          ],
        ),
      ),
    );
  }
}
