import 'package:flutter/material.dart';
import 'package:lang_words/routes/routes.dart';

import '../../constants/sizes.dart';
import '../ui/icon_button_square.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    this.text,
    required this.onDrawerToggle,
    Key? key,
  }) : super(key: key);

  final String? text;
  final VoidCallback onDrawerToggle;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final routeName = ModalRoute.of(context)!.settings.name ?? '';
    final title = routeName.contains(RoutesUtil.routeLoggedProfilePage)
        ? 'Profile'
        : routeName.contains(RoutesUtil.routeLoggedKnownWordsPage)
            ? 'Known Words'
            : routeName.contains(RoutesUtil.routeLoggedWordsPage)
                ? 'Words'
                : 'Unknown Page';

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
  }
}
