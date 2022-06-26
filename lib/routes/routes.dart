import 'package:flutter/material.dart';

class RoutesUtil {
  static final rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root navigation key',
  );
  static final loggedNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'nested "logged in" navigation key',
  );

  static const String routeAuth = '/auth';
  static const String routePrefixLogged = '/logged';

  static const String routeLoggedHome =
      '$routePrefixLogged$routeLoggedWordsPage';

  static const String routeLoggedWordsPage = '/words';
  static const String routeLoggedKnownWordsPage = '/known-words';
  static const String routeLoggedProfilePage = '/profile';
}
