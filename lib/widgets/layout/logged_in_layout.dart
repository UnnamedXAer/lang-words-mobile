import 'dart:developer';

import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../models/word.dart';
import '../../pages/words/words_page.dart';
import '../../services/words_service.dart';
import '../../widgets/layout/app_drawer.dart';
import '../../widgets/layout/app_nav_bar.dart';
import '../../widgets/work_section_container.dart';
import '../logo_text.dart';

class LoggedInLayout extends StatefulWidget {
  static const routeName = '/loggedIn';
  const LoggedInLayout({Key? key}) : super(key: key);

  @override
  State<LoggedInLayout> createState() => _LoggedInLayoutState();
}

class _LoggedInLayoutState extends State<LoggedInLayout> {
  List<Word> _words = [];
  String? _fetchError;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();

    _fetchMyWords();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final bigSize = screenWidth > Sizes.minWidth;

    return Scaffold(
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
                child: AppNavBar(text: bigSize ? 'Words' : null),
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
                    const Expanded(child: AppDrawer()),
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
                  child: WordsPage(
                    fetching: _fetching,
                    fetchError: _fetchError,
                    words: _words,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchMyWords() async {
    final ws = WordsService();
    _fetching = true;
    try {
      final userWords = await ws.fetchWords('upVdWx9mrAdQeJ2DYrCZQrASEUj1');
      _words = userWords;
    } catch (err) {
      _fetchError = (err as Error).toString();

      log('fetch words err: $err');
    } finally {
      setState(() {
        _fetching = false;
      });
    }
  }
}
