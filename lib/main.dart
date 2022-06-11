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
        inputDecorationTheme: const InputDecorationTheme(
          fillColor: AppColors.bgInput,
          border: InputBorder.none,
          filled: true,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.borderInputFocus,
              width: 5,
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
      home: AuthPage(),
    );
  }
}
