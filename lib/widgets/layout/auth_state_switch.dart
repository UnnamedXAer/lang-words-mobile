import 'dart:developer';

import 'package:flutter/material.dart';

import '../../pages/auth/auth_page.dart';
import '../inherited/auth_state.dart';
import '../ui/spinner.dart';
import 'logged_in_layout.dart';
import 'main_layout.dart';

class AuthStateSwitch extends StatelessWidget {
  const AuthStateSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authInfo = AuthInfo.of(context);

    Widget page;

    if (authInfo.isLoggedIn == true) {
      page = const MainLayout(
        key: ValueKey('LoggedIn pages'),
        page: LoggedInLayout(),
      );
    } else if (authInfo.isLoggedIn == false) {
      page = const MainLayout(
        key: ValueKey('Auth pages'),
        page: AuthPage(),
      );
    } else {
      page = const Center(
        key: ValueKey('spinner - auth'),
        child: Spinner(
          size: SpinnerSize.large,
        ),
      );
    }

    const Duration switchDuration = Duration(milliseconds: 300);
    log('⏭ AuthStateSwitch - is logged: ${authInfo.isLoggedIn}, about to switch to: ${page.key.toString()}');

    return AnimatedSwitcher(
      duration: switchDuration,
      reverseDuration: switchDuration,
      child: page,
      transitionBuilder: (child, animation) {
        log('⏭ AuthStateSwitch / 🔱 AnimatedSwitcher ${animation.value}, ${child.key}');
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation.drive(
              Tween(begin: 0.85, end: 1),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
