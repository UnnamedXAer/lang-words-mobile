import 'dart:developer';

import 'package:flutter/material.dart';

import '../../models/word.dart';
import '../../pages/words/words_page.dart';
import '../../services/words_service.dart';
import '../../widgets/layout/app_drawer.dart';
import '../../widgets/layout/app_nav_bar.dart';
import '../../widgets/work_section_container.dart';

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
    const drawerWidth = 320.0;

    return Scaffold(
      body: SafeArea(
        child: WorkSectionContainer(
          withMargin: false,
          child: Stack(
            alignment: AlignmentDirectional.topCenter,
            children: [
              const AppNavBar(),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                top: kBottomNavigationBarHeight,
                bottom: 0,
                left: screenWidth > 648 ? 0 : -drawerWidth,
                width: drawerWidth,
                child: const AppDrawer(),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                top: kBottomNavigationBarHeight,
                bottom: 0,
                right: 0,
                left: screenWidth > 648 ? drawerWidth : 0.0,
                child: WordsPage(
                  fetching: _fetching,
                  fetchError: _fetchError,
                  words: _words,
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
