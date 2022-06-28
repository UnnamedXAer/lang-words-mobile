import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lang_words/widgets/app_drawer_content.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../widgets/layout/app_nav_bar.dart';
import '../../widgets/work_section_container.dart';
import '../logo_text.dart';
import 'app_drawer.dart';
import 'logged_nested_navigator.dart';

class LoggedInLayout extends StatefulWidget {
  const LoggedInLayout({Key? key}) : super(key: key);

  @override
  State<LoggedInLayout> createState() => _LoggedInLayoutState();
}

class _LoggedInLayoutState extends State<LoggedInLayout> {
  final _navKey = GlobalKey<AppDrawerState>();
  final _routeName = ValueNotifier<String>('/');

  void _toggleDrawer() {
    log('toggle drawer but not');
    _navKey.currentState?.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final bigSize = screenWidth > Sizes.minWidth;
    log('building logged layout 🔳');
    return AppDrawer(
      key: _navKey,
      drawerContent: AppDrawerContent(
        onItemPressed: _toggleDrawer,
      ),
      page: Scaffold(
        body: SafeArea(
          child: WorkSectionContainer(
            withMargin: false,
            child: Stack(
              alignment: AlignmentDirectional.topCenter,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    height: kBottomNavigationBarHeight,
                    width: screenWidth,
                    alignment: Alignment.center,
                    color: AppColors.bgHeader,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: bigSize ? Sizes.drawerWidth : 0,
                  child: AppNavBar(
                    onDrawerToggle: _toggleDrawer,
                    routeName: _routeName,
                    text: bigSize ? _routeName.value : null,
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 2200),
                  top: 0,
                  bottom: 0,
                  left: screenWidth > Sizes.minWidth ? 0 : -Sizes.drawerWidth,
                  width: Sizes.drawerWidth,
                  child: Column(
                    children: [
                      Container(
                        height: kBottomNavigationBarHeight,
                        color: AppColors.bgHeader,
                        alignment: Alignment.center,
                        width: Sizes.drawerWidth,
                        child: const LogoText(),
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
                Positioned(
                  // duration: const Duration(milliseconds: 2200),
                  top: kBottomNavigationBarHeight,
                  bottom: 0,
                  right: 0,
                  left: screenWidth > Sizes.minWidth ? Sizes.drawerWidth : 0.0,
                  child: LoggedNestedNavigator(routeName: _routeName),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
