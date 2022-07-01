import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/colors.dart';
import '../../pages/profile_page.dart';
import '../../pages/words/words_page.dart';
import '../../routes/routes.dart';

class LoggedNestedNavigator extends StatefulWidget {
  const LoggedNestedNavigator({
    Key? key,
    required ValueNotifier<String> routeName,
  })  : _routeName = routeName,
        super(key: key);

  final ValueNotifier<String> _routeName;

  @override
  State<LoggedNestedNavigator> createState() => _LoggedNestedNavigatorState();
}

class _LoggedNestedNavigatorState extends State<LoggedNestedNavigator> {
  DateTime? lastPopTriedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgWorkSection,
      child: WillPopScope(
        onWillPop: (() async {
          DateTime now = DateTime.now();
          const duration = Duration(seconds: 1);
          if (lastPopTriedAt == null ||
              lastPopTriedAt!.difference(now) > duration) {
            lastPopTriedAt = now;

            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'press again to exit',
                ),
                duration: duration,
              ),
            );

            return false;
          }

          SystemNavigator.pop();
          return true;
        }),
        child: Navigator(
          key: RoutesUtil.loggedNavigatorKey,
          initialRoute: RoutesUtil.routeLoggedStart,
          onGenerateRoute: (settings) {
            final String name = settings.name == '/' || settings.name == null
                ? RoutesUtil.routeLoggedWordsPage
                : settings.name!;

            Future.delayed(Duration.zero, () => widget._routeName.value = name);

            late Widget page;

            switch (name) {
              case '/':
              case RoutesUtil.routeLoggedWordsPage:
              case RoutesUtil.routeLoggedKnownWordsPage:
                page = WordsPage(
                  isKnownWords: name == RoutesUtil.routeLoggedKnownWordsPage,
                );
                break;
              case RoutesUtil.routeLoggedProfilePage:
                page = const ProfilePage();
                break;

              default:
                throw Exception('Unknown nested route: $name');
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
