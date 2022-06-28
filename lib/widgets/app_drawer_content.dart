import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lang_words/routes/routes.dart';

import '../constants/colors.dart';

class AppDrawerContent extends StatelessWidget {
  const AppDrawerContent({
    Key? key,
    required VoidCallback onItemPressed,
  })  : _onItemPressed = onItemPressed,
        super(key: key);

  final VoidCallback _onItemPressed;

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
            Container(
              height: 1,
              decoration: const BoxDecoration(
                // color: Colors.white,
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.white54],
                  stops: [0.00, 0.9],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavItem(
                      labelText: 'Words',
                      onPressed: _getNavigationFn(
                        context,
                        RoutesUtil.routeLoggedWordsPage,
                      ),
                    ),
                    _buildNavItem(
                      labelText: 'Known Words',
                      onPressed: _getNavigationFn(
                        context,
                        RoutesUtil.routeLoggedKnownWordsPage,
                      ),
                    ),
                    _buildNavItem(
                      labelText: 'Profile',
                      onPressed: _getNavigationFn(
                        context,
                        RoutesUtil.routeLoggedProfilePage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  TextButton _buildNavItem({
    required String labelText,
    required void Function() onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        ),
        foregroundColor: MaterialStateProperty.all(
          const Color.fromRGBO(64, 224, 208, 1),
        ),
        textStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 20,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(labelText),
      ),
    );
  }

  VoidCallback _getNavigationFn(BuildContext context, String routeName) {
    return () {
      final oldRouteName =
          ModalRoute.of(RoutesUtil.loggedNavigatorKey.currentContext!)
              ?.settings
              .name;
      log('\nnavigating to: $routeName from: $oldRouteName');
      // if ((oldRouteName ?? '').endsWith(routeName)) {
      //   return;
      // }
      RoutesUtil.loggedNavigatorKey.currentState?.pushNamed(routeName);
      _onItemPressed();
    };
  }
}
