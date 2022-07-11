import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lang_words/pages/auth/forgot_password_page.dart';
import 'package:lang_words/pages/auth/forgot_password_success_page.dart';
import 'package:lang_words/pages/not_found_page.dart';
import 'package:lang_words/routes/routes.dart';

import 'constants/colors.dart';
import 'constants/sizes.dart';
import 'pages/auth/auth_page.dart';
import 'pages/dummy_page.dart';
import 'widgets/layout/app_drawer.dart';
import 'widgets/layout/logged_in_layout.dart';

void main() async {
  await initializeDateFormatting(Platform.localeName);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
      initialRoute: RoutesUtil.routeAuth,
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
        if (settings.name == DummyPage.routeName) {
          return MaterialPageRoute<dynamic>(
            builder: (_) => const DummyPage(),
            settings: settings,
          );
        }

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
