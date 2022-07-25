import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';

class AuthState extends StatefulWidget {
  const AuthState({required this.child, Key? key}) : super(key: key);

  final Widget child;

  @override
  State<AuthState> createState() => _AuthStateState();
}

class _AuthStateState extends State<AuthState> {
  bool? isLoggedIn;
  AppUser? appUser;
  late final StreamSubscription<AppUser?> _subscription;

  @override
  void initState() {
    super.initState();

    log('about to add listener for user');
    _subscription = AuthService().addUserListener((AppUser? user) {
      setState(() {
        final old = isLoggedIn;
        isLoggedIn = user != null;
        log('setting isLogged from: $old to: $isLoggedIn');
        appUser = user;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log('!!! _AuthStateState - is logged: $isLoggedIn');

    return AuthInfo(
      appUser: appUser,
      isLoggedIn: isLoggedIn,
      child: widget.child,
    );
  }
}

class AuthInfo extends InheritedWidget {
  final bool? isLoggedIn;
  final AppUser? appUser;

  const AuthInfo({
    required this.isLoggedIn,
    required this.appUser,
    Key? key,
    required super.child,
  }) : super(key: key);

  static AuthInfo of(BuildContext context) {
    final AuthInfo instance =
        (context.dependOnInheritedWidgetOfExactType<AuthInfo>()!);
    log('instance: ${instance.isLoggedIn}');
    return instance;
  }

  @override
  bool updateShouldNotify(AuthInfo oldWidget) {
    final equal = oldWidget.appUser != appUser;
    return equal;
  }
}
