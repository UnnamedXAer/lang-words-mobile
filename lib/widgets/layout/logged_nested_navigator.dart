import 'dart:developer';

import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../pages/profile_page.dart';
import '../../pages/words/words_page.dart';
import '../../routes/routes.dart';

class LoggedNestedNavigator extends StatelessWidget {
  const LoggedNestedNavigator({
    Key? key,
    required ValueNotifier<String> routeName,
  })  : _routeName = routeName,
        super(key: key);

  final ValueNotifier<String> _routeName;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgWorkSection,
      child: WillPopScope(
        onWillPop: (() async {
          final shouldPop =
              await (RoutesUtil.loggedNavigatorKey.currentState?.maybePop());

          return shouldPop == null ? true : !shouldPop;
        }),
        child: Navigator(
          key: RoutesUtil.loggedNavigatorKey,
          initialRoute: RoutesUtil.routeLoggedStart,
          onGenerateRoute: (settings) {
            log('nested router: ${settings.name}');
            _routeName.value = settings.name ?? '';

            late Widget page;

            switch (settings.name) {
              case '/':
              case RoutesUtil.routeLoggedWordsPage:
              case RoutesUtil.routeLoggedKnownWordsPage:
                page = WordsPage(
                  isKnownWords:
                      settings.name == RoutesUtil.routeLoggedKnownWordsPage,
                );
                break;
              case RoutesUtil.routeLoggedProfilePage:
                page = const ProfilePage();
                break;

              default:
                throw Exception('Unknown nested route: ${settings.name}');
            }

            return MaterialPageRoute<dynamic>(
              builder: (_) => page,
              settings: settings,
            );
          },
        ),
      ),
    );
  }
}
