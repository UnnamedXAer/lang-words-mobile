import 'package:flutter/material.dart';

import '../constants/colors.dart';

class AppDrawerContent extends StatelessWidget {
  const AppDrawerContent({
    Key? key,
  }) : super(key: key);

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
                    _buildNavItem(labelText: 'Words', onPressed: () {
                      Navigator.of(context).pushNamed('/words');
                    }),
                    _buildNavItem(labelText: 'Known Words', onPressed: () {
                      Navigator.of(context).pushNamed('/known-words');
                    }),
                    _buildNavItem(labelText: 'Profile', onPressed: () {
                      Navigator.of(context).pushNamed('/profile');
                    }),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: kBottomNavigationBarHeight,
              child: TextButton(
                child: const Text('LOGOUT'),
                onPressed: () {
                  // logout
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
}
