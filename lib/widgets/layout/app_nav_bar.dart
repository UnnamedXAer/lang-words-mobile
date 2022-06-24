import 'package:flutter/material.dart';

import '../../constants/sizes.dart';
import '../ui/icon_button_square.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bigSize = MediaQuery.of(context).size.width > Sizes.maxWidth;

    return Container(
      alignment: Alignment.topCenter,
      child: Container(
          width: double.infinity,
          color: Theme.of(context).appBarTheme.backgroundColor,
          height: kBottomNavigationBarHeight,
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              children: [
                if (bigSize) LogoText(),
                if (bigSize)
                  Text('Words')
                else
                  IconButtonSquare(
                    onTap: () {},
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
