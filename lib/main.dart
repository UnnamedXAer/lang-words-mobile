import 'package:flutter/material.dart';

import 'constants/colors.dart';
import 'pages/auth_page.dart';

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
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          surface: Colors.purple.shade300,
          onSurface: AppColors.text,
          background: AppColors.bg,
          onBackground: AppColors.text,
          error: AppColors.error,
          onError: AppColors.textLight,
          primary: AppColors.primary,
          onPrimary: AppColors.textLight,
          secondary: AppColors.secondary,
          onSecondary: AppColors.bg,
          /////////// dummy colors
          outline: Colors.deepOrange,
          tertiary: Colors.yellow.shade700,
          shadow: Colors.pink.shade400,
          surfaceTint: Colors.amber.shade800,
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
      ),
      home: const AuthPage(),
    );
  }
}
