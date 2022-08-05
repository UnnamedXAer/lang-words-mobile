 import 'package:flutter/material.dart';

import '../../constants/colors.dart';

ThemeData buildDarkTheme(BuildContext context) {
    return ThemeData(
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
      );
  }