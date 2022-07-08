import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lang_words/pages/profile_page.dart';
import 'package:lang_words/routes/routes.dart';

import '../constants/colors.dart';
import 'ui/fading_separator.dart';

class AppDrawerContent extends StatelessWidget {
  const AppDrawerContent({
    Key? key,
    required VoidCallback onItemPressed,
    required this.selectedIndex,
    required this.onDestinationSelected,
  })  : _onItemPressed = onItemPressed,
        super(key: key);

  final VoidCallback _onItemPressed;
  final int selectedIndex;
  final void Function(int)? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: double.infinity,
        color: AppColors.bgDrawer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Hello'),
                  Text('test@test.com'),
                ],
              ),
            ),
            const FadingSeparator(),
            Expanded(
              child: NavigationRail(
                backgroundColor: Colors.transparent,
                extended: true,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                // minExtendedWidth: MediaQuery.of(context).size.width,
                indicatorColor: AppColors.primary,

                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.layers),
                    label: _buildNavItem(
                      labelText: 'Words',
                      onPressed: _getNavigationFn(
                        context,
                        RoutesUtil.routeLoggedWordsPage,
                      ),
                    ),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.yard_outlined),
                    label: _buildNavItem(
                      labelText: 'Known Words',
                      onPressed: _getNavigationFn(
                        context,
                        RoutesUtil.routeLoggedKnownWordsPage,
                      ),
                    ),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.account_box_outlined),
                    label: _buildNavItem(
                      labelText: 'Profile',
                      onPressed: _getNavigationFn(
                        context,
                        RoutesUtil.routeLoggedProfilePage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // const FadingSeparator(),
            // Expanded(
            //   child: SizedBox(
            //     width: double.infinity,
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.stretch,
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         _buildNavItem(
            //           labelText: 'Words',
            //           onPressed: _getNavigationFn(
            //             context,
            //             RoutesUtil.routeLoggedWordsPage,
            //           ),
            //         ),
            //         _buildNavItem(
            //           labelText: 'Known Words',
            //           onPressed: _getNavigationFn(
            //             context,
            //             RoutesUtil.routeLoggedKnownWordsPage,
            //           ),
            //         ),
            //         _buildNavItem(
            //           labelText: 'Profile',
            //           onPressed: _getNavigationFn(
            //             context,
            //             RoutesUtil.routeLoggedProfilePage,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            SizedBox(
              height: kBottomNavigationBarHeight,
              child: TextButton(
                child: const Text('LOGOUT'),
                onPressed: () {
                  RoutesUtil.rootNavigatorKey.currentState
                      ?.popUntil(ModalRoute.withName('/'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String labelText,
    required void Function() onPressed,
  }) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Text(
        labelText,
        style: const TextStyle(
          color: Color.fromRGBO(64, 224, 208, 1),
          fontSize: 20,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
  // TextButton _buildNavItem({
  //   required String labelText,
  //   required void Function() onPressed,
  // }) {
  //   return TextButton(
  //     onPressed: onPressed,
  //     style: ButtonStyle(
  //       padding: MaterialStateProperty.all(
  //         const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
  //       ),
  //       foregroundColor: MaterialStateProperty.all(
  //         const Color.fromRGBO(64, 224, 208, 1),
  //       ),
  //       textStyle: MaterialStateProperty.all(
  //         const TextStyle(
  //           fontSize: 20,
  //           fontStyle: FontStyle.italic,
  //           fontWeight: FontWeight.w400,
  //         ),
  //       ),
  //     ),
  //     child: Align(
  //       alignment: Alignment.centerLeft,
  //       child: Text(labelText),
  //     ),
  //   );
  // }

  VoidCallback _getNavigationFn(BuildContext context, String routeName) {
    return () {
      final oldRouteName =
          ModalRoute.of(RoutesUtil.loggedNavigatorKey.currentContext!)
              ?.settings
              .name;
      log('\nnavigating to: $routeName from: $oldRouteName');
      // RoutesUtil.loggedNavigatorKey.currentState?.pushNamed(routeName);
      // _onItemPressed();
      // onDestinationSelected?.call(1);
    };
  }
}
