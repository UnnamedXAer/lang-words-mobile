import 'package:flutter/material.dart';

import 'constants/colors.dart';
import 'constants/sizes.dart';
import 'pages/auth/auth_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/auth/forgot_password_success_page.dart';
import 'widgets/layout/logged_in_layout.dart';

void main() {
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
          )),
      home: const _MainLayout(page: AuthPage()),
      // home: const MainScaffold(child: WordsPage()),
      routes: {
        // todo: when auth completed show only auth or other routes

        // auth
        AuthPage.routeName: (context) => const _MainLayout(
              page: AuthPage(),
            ),
        ForgotPasswordPage.routeName: (context) => const _MainLayout(
              page: ForgotPasswordPage(),
            ),
        ForgotPasswordSuccessPage.routeName: (context) => const _MainLayout(
              page: ForgotPasswordSuccessPage(),
            ),

        // or logged in
        LoggedInLayout.routeName: (context) => const _MainLayout(
              page: LoggedInLayout(),
            ),
      },
    );
  }
}

class _MainLayout extends StatelessWidget {
  const _MainLayout({
    required this.page,
    Key? key,
  }) : super(key: key);

  final Widget page;

  @override
  Widget build(BuildContext context) {
    final bigScreen = MediaQuery.of(context).size.width >= Sizes.maxWidth;
    final double margin = bigScreen ? 19 : 0;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints:
                const BoxConstraints(minWidth: 330, maxWidth: Sizes.maxWidth),
            margin: EdgeInsets.all(margin),
            child: page,
          ),
        ],
      ),
    );
  }
}
