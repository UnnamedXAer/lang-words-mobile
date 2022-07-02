import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';
import 'package:lang_words/routes/routes.dart';

import '../../constants/sizes.dart';
import '../logo_text.dart';
import '../ui/icon_button_square.dart';
import '../words/add_word.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required bool isMediumScreen,
    required VoidCallback toggleDrawer,
    required ValueNotifier<String> routeName,
    Key? key,
  })  : _isMediumScreen = isMediumScreen,
        _toggleDrawer = toggleDrawer,
        _routeName = routeName,
        super(key: key);

  final bool _isMediumScreen;
  final VoidCallback _toggleDrawer;
  final ValueNotifier<String> _routeName;

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.bgHeader,
            height: kBottomNavigationBarHeight,
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  IconButtonSquare(
                    onTap: _toggleDrawer,
                    size: kBottomNavigationBarHeight,
                    icon: const Icon(Icons.menu_outlined),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: Sizes.paddingBig,
                    ),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: _isMediumScreen
                        ? Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: Sizes.paddingBig,
                            ),
                            child: const LogoText(),
                          )
                        : const SizedBox(),
                  ),
                  IconButtonSquare(
                    onTap: () {},
                    size: kBottomNavigationBarHeight,
                    icon: const Icon(Icons.refresh_outlined),
                  ),
                  IconButtonSquare(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddWord(),
                      );
                    },
                    size: kBottomNavigationBarHeight,
                    icon: const Icon(Icons.add_outlined),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
