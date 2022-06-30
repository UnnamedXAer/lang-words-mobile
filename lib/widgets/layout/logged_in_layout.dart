import 'package:flutter/material.dart';
import 'package:lang_words/widgets/app_drawer_content.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../widgets/layout/app_nav_bar.dart';
import '../../widgets/work_section_container.dart';
import 'app_drawer.dart';
import 'logged_nested_navigator.dart';

class LoggedInLayout extends StatefulWidget {
  const LoggedInLayout({Key? key}) : super(key: key);

  @override
  State<LoggedInLayout> createState() => _LoggedInLayoutState();
}

class _LoggedInLayoutState extends State<LoggedInLayout> {
  final _routeName = ValueNotifier<String>('/');

  void _toggleDrawer() {
    AppDrawer.navKey.currentState?.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final mediumScreen = screenSize.width >= Sizes.minWidth;
    return AppDrawer(
      key: AppDrawer.navKey,
      drawerContent: AppDrawerContent(
        onItemPressed: _toggleDrawer,
      ),
      page: Scaffold(
        backgroundColor: AppColors.bgHeader,
        body: SafeArea(
          child: WorkSectionContainer(
            withMargin: false,
            child: Column(
              children: [
                AppNavBar(
                  toggleDrawer: _toggleDrawer,
                  routeName: _routeName,
                  isMediumScreen: mediumScreen,
                ),
                Expanded(
                  child: LoggedNestedNavigator(
                    routeName: _routeName,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
