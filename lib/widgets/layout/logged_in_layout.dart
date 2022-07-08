import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lang_words/pages/profile_page.dart';
import 'package:lang_words/pages/words/words_page.dart';
import 'package:lang_words/widgets/app_drawer_content.dart';
import 'package:lang_words/widgets/error_text.dart';

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

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final mediumScreen = screenSize.width >= Sizes.minWidth;

    late final Widget pageContent;
    switch (_selectedIndex) {
      case 0:
        pageContent = const WordsPage(
          key: ValueKey('Words'),
          isKnownWords: false,
        );
        break;
      case 1:
        pageContent = const WordsPage(
          key: ValueKey('KnownWords'),
          isKnownWords: true,
        );
        break;
      case 2:
        pageContent = const ProfilePage(
          key: ValueKey('Profile'),
        );
        break;
      default:
        pageContent = Container(
          color: AppColors.warning,
          child: ErrorText('Not Found'),
        );
    }
    return AppDrawer(
      key: AppDrawer.navKey,
      drawerContent: AppDrawerContent(
        onItemPressed: _toggleDrawer,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          log('set index: $i');
          setState(() {
            _selectedIndex = i;
          });
        },
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
                  child: pageContent,
                ),
                // Expanded(
                //   child: LoggedNestedNavigator(
                //     routeName: _routeName,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
