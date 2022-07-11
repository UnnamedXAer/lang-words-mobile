import 'package:flutter/material.dart';
import 'package:lang_words/routes/routes.dart';

import '../constants/colors.dart';
import 'ui/fading_separator.dart';

class AppDrawerContent extends StatelessWidget {
  const AppDrawerContent({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

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
                indicatorColor: AppColors.primary,
                destinations: [
                  _buildNavItem(
                    icon: const Icon(Icons.layers),
                    labelText: 'Words',
                  ),
                  _buildNavItem(
                    icon: const Icon(Icons.library_add_check),
                    labelText: 'Known Words',
                  ),
                  _buildNavItem(
                    icon: const Icon(Icons.person, size: 28),
                    labelText: 'Profile',
                  ),
                ],
              ),
            ),
            SizedBox(
              height: kBottomNavigationBarHeight,
              child: TextButton(
                child: const Text('LOGOUT'),
                onPressed: () {
                  Navigator.of(context).popUntil(
                    ModalRoute.withName(RoutesUtil.routeAuth),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  NavigationRailDestination _buildNavItem({
    required Widget icon,
    required String labelText,
  }) {
    return NavigationRailDestination(
      icon: icon,
      label: Container(
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
      ),
    );
  }
}
