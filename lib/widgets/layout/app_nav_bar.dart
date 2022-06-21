import 'package:flutter/material.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        color: Theme.of(context).appBarTheme.backgroundColor,
        height: kBottomNavigationBarHeight,
        child: TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('pop'),
        ),
      ),
    );
  }
}