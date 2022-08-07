import 'package:flutter/widgets.dart';

enum Environment {
  dev,
  stage,
  prod,
}

class AppConfig extends InheritedWidget {
  final Environment env;

  const AppConfig({
    required this.env,
    required Widget child,
    Key? key,
  }) : super(
          key: key,
          child: child,
        );

  AppConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppConfig>()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
