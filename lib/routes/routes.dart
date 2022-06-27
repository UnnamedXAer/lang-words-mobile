import 'package:flutter/material.dart';

class RoutesUtil {
  static final rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root navigation key',
  );
  static final loggedNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'nested "logged in" navigation key',
  );

  static const String routeAuth = '/auth';
  static const routeAuthForgotPassword = '$routeAuth/forgot-password';
  static const routeAuthForgotPasswordSuccess =
      '$routeAuth/forgot-password-success';

  static const String routePrefixLogged = '/logged';

  static const String routeLoggedHome =
      '$routePrefixLogged$routeLoggedWordsPage';

  static const String routeLoggedStart = '/';
  static const String routeLoggedWordsPage = '/words';
  static const String routeLoggedKnownWordsPage = '/known';
  static const String routeLoggedProfilePage = '/profile';
}
