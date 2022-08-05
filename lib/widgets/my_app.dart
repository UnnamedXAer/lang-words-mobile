import 'package:flutter/material.dart';
import 'package:lang_words/pages/auth/forgot_password_page.dart';
import 'package:lang_words/pages/auth/forgot_password_success_page.dart';
import 'package:lang_words/pages/not_found_page.dart';
import 'package:lang_words/routes/routes.dart';

import '../constants/colors.dart';
import '../pages/auth/auth_page.dart';
import 'helpers/theme.dart';
import 'inherited/auth_state.dart';
import 'layout/auth_state_switch.dart';
import 'layout/logged_in_layout.dart';
import 'layout/main_layout.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthState(
      child: MaterialApp(
        title: 'Lang Words',
        color: AppColors.primary,
        themeMode: ThemeMode.dark,
        darkTheme: buildDarkTheme(context),
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
    );
  }
}
