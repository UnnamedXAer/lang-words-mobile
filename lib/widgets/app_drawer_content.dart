import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/words_service.dart';
import 'inherited/auth_state.dart';
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
    final String email = AuthInfo.of(context).appUser?.email ?? '';
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
                children: [
                  const Text('Hello'),
                  Text(email),
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
                  final ws = WordsService();
                  ws.clear();
                  final authService = AuthService();
                  authService.logout();
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
