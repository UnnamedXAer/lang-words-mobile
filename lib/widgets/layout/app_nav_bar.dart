import 'package:flutter/material.dart';

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
                const Expanded(child: SizedBox()),
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
