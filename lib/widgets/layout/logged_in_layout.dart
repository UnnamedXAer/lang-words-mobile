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

class LoggedInLayout extends StatefulWidget {
  const LoggedInLayout({Key? key}) : super(key: key);

  @override
  State<LoggedInLayout> createState() => _LoggedInLayoutState();
}

class _LoggedInLayoutState extends State<LoggedInLayout> {
  int _selectedIndex = 0;

  void _toggleDrawer() {
    AppDrawer.navKey.currentState?.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final mediumScreen = screenSize.width >= Sizes.minWidth;

    late String title;

    late final Widget pageContent;
    switch (_selectedIndex) {
      case 0:
        title = 'Words';
        pageContent = const WordsPage(
          key: ValueKey('Words'),
          isKnownWords: false,
        );
        break;
      case 1:
        title = 'Known Words';
        pageContent = const WordsPage(
          key: ValueKey('KnownWords'),
          isKnownWords: true,
        );
        break;
      case 2:
        title = 'Profile';
        pageContent = const ProfilePage(
          key: ValueKey('Profile'),
        );
        break;
      default:
        title = 'Unknown';
        pageContent = Container(
          color: AppColors.warning,
          child: const ErrorText('Not Found'),
        );
    }
    return AppDrawer(
      key: AppDrawer.navKey,
      drawerContent: AppDrawerContent(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() {
            _selectedIndex = i;
          });
          _toggleDrawer();
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
                  title: title,
                  isMediumScreen: mediumScreen,
                ),
                Expanded(
                  child: pageContent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
