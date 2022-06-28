import 'package:flutter/material.dart';
import 'package:lang_words/routes/routes.dart';

import '../../constants/sizes.dart';
import '../ui/icon_button_square.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    this.text,
    required this.onDrawerToggle,
    required ValueNotifier<String> routeName,
    Key? key,
  })  : _routeName = routeName,
        super(key: key);

  final String? text;
  final VoidCallback onDrawerToggle;
  final ValueNotifier<String> _routeName;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _routeName,
      builder: (BuildContext context, Widget? child) {
        late String title;
        switch (_routeName.value) {
          case '/':
          case RoutesUtil.routeLoggedWordsPage:
            title = 'Words';
            break;
          case RoutesUtil.routeLoggedKnownWordsPage:
            title = 'Known Words';
            break;
          case RoutesUtil.routeLoggedProfilePage:
            title = 'Profile';
            break;
          default:
            title = 'Unknown Page';
        }
        return Container(
          alignment: Alignment.topCenter,
          child: Container(
              width: screenWidth <= Sizes.minWidth
                  ? screenWidth
                  : screenWidth - Sizes.drawerWidth,
              color: Theme.of(context).appBarTheme.backgroundColor,
              height: kBottomNavigationBarHeight,
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  children: [
                    if (text != null)
                      Text(text!)
                    else
                      IconButtonSquare(
                        onTap: onDrawerToggle,
                        size: kBottomNavigationBarHeight,
                        icon: const Icon(Icons.menu_outlined),
                      ),
                    Expanded(child: Text(title)),
                    IconButtonSquare(
                      onTap: () {},
                      size: kBottomNavigationBarHeight,
                      icon: const Icon(Icons.refresh_outlined),
                    ),
                    IconButtonSquare(
                      onTap: () {},
                      size: kBottomNavigationBarHeight,
                      icon: const Icon(Icons.add_outlined),
                    ),
                  ],
                ),
              )),
        );
      },
    );
  }
}
