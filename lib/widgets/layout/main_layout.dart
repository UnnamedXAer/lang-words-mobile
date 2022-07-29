import 'package:flutter/material.dart';

import '../../constants/sizes.dart';
import 'app_drawer.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({
    required Widget page,
    Key? key,
  })  : _page = page,
        super(key: key);

  final Widget _page;

  @override
  Widget build(BuildContext context) {
    final bigScreen = MediaQuery.of(context).size.width >= Sizes.maxWidth;
    final double margin = bigScreen ? 19 : 0;

    return GestureDetector(
      onTap: () {
        AppDrawer.navKey.currentState?.toggle(false);
      },
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints:
                  const BoxConstraints(minWidth: 330, maxWidth: Sizes.maxWidth),
              margin: EdgeInsets.all(margin),
              child: _page,
            ),
          ],
        ),
      ),
    );
  }
}
