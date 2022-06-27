import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lang_words/pages/profile_page.dart';
import 'package:lang_words/routes/routes.dart';
import 'package:lang_words/widgets/app_drawer_content.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../models/word.dart';
import '../../pages/words/words_page.dart';
import '../../services/words_service.dart';
import '../../widgets/layout/app_nav_bar.dart';
import '../../widgets/work_section_container.dart';
import '../logo_text.dart';
import 'app_drawer.dart';

class LoggedInLayout extends StatefulWidget {
  const LoggedInLayout({Key? key}) : super(key: key);

  @override
  State<LoggedInLayout> createState() => _LoggedInLayoutState();
}

class _LoggedInLayoutState extends State<LoggedInLayout> {
  void _toggleDrawer() {
    // log('toggle drawer but not');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final bigSize = screenWidth > Sizes.minWidth;
    log('building logged layout');
    return AppDrawer(
      drawerContent: const AppDrawerContent(),
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
                    text: bigSize ? 'Words' : null,
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
                  child: Container(
                    color: AppColors.bgWorkSection,
                    child: WillPopScope(
                      onWillPop: (() async {
                        final shouldPop = await (RoutesUtil
                            .loggedNavigatorKey.currentState
                            ?.maybePop());

                        return shouldPop == null ? true : !shouldPop;
                      }),
                      child: Navigator(
                        key: RoutesUtil.loggedNavigatorKey,
                        initialRoute: RoutesUtil.routeLoggedStart,
                        onGenerateRoute: (settings) {
                          log('nested router: ${settings.name}');

                          late Widget page;

                          switch (settings.name) {
                            case '/':
                            case RoutesUtil.routeLoggedWordsPage:
                            case RoutesUtil.routeLoggedKnownWordsPage:
                              page = WordsPage(
                                isKnownWords: settings.name ==
                                    RoutesUtil.routeLoggedKnownWordsPage,
                              );
                              break;
                            case RoutesUtil.routeLoggedProfilePage:
                              page = const ProfilePage();
                              break;

                            default:
                              throw Exception(
                                  'Unknown nested route: ${settings.name}');
                          }

                          return MaterialPageRoute<dynamic>(
                            builder: (_) => page,
                            settings: settings,
                          );
                        },
                      ),
                    ),
                    // child: WordsPage(
                    //   fetching: _fetching,
                    //   fetchError: _fetchError,
                    //   words: _words,
                    // ),
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
