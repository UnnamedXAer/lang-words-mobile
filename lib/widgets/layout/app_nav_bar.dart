import 'package:flutter/material.dart';

import '../../constants/sizes.dart';
import '../logo_text.dart';

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
            child: Row(
              children: [
                if (bigSize) LogoText(),
                if (bigSize)
                  Text('Words')
                else
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.menu_outlined),
                  ),
                const Expanded(child: SizedBox()),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh_outlined),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_outlined),
                ),
              ],
            ),
          )),
    );
  }
}
