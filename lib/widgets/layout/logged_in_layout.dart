import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lang_words/pages/profile_page.dart';
import 'package:lang_words/pages/words/words_page.dart';
import 'package:lang_words/widgets/app_drawer_content.dart';
import 'package:lang_words/widgets/error_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../services/words_service.dart';
import '../../widgets/layout/app_nav_bar.dart';
import '../../widgets/work_section_container.dart';
import '../inherited/auth_state.dart';
import '../words/edit_word.dart';
import 'app_drawer.dart';

class LoggedInLayout extends StatefulWidget {
  const LoggedInLayout({Key? key}) : super(key: key);

  @override
  State<LoggedInLayout> createState() => _LoggedInLayoutState();
}

class _LoggedInLayoutState extends State<LoggedInLayout> {
  late final StreamSubscription<ConnectivityResult> _connectivitySubscription;

  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      setState(() {
        _isConnected = result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi;
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();

    super.dispose();
  }

  int _selectedIndex = 0;

  void _toggleDrawer() {
    AppDrawer.navKey.currentState?.toggle();
  }

  late final Map<ShortcutActivator, VoidCallback> _keyBindings = {
    LogicalKeySet(
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.keyA,
    ): () {
      showDialog(
        context: context,
        builder: (_) => const EditWord(),
      );
    },
    LogicalKeySet(
      LogicalKeyboardKey.keyR,
    ): () {
      if (_selectedIndex == 0 || _selectedIndex == 1) {
        final uid = AuthInfo.of(context).uid;
        WordsService().fetchWords(uid);
      }
    },
  };

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
      setSelectedIndex: (int i) {
        setState(() {
          _selectedIndex = i;
        });
      },
      drawerContent: AppDrawerContent(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() {
            _selectedIndex = i;
          });
          _toggleDrawer();
        },
      ),
      page: Focus(
        debugLabel: 'Focus - Drawer.page',
        autofocus: true,
        onKey: _onKeyHandler,
        child: Scaffold(
          backgroundColor: AppColors.bgHeader,
          body: SafeArea(
            child: WorkSectionContainer(
              withMargin: false,
              child: Column(
                children: [
                  AppNavBar(
                    toggleDrawer: _toggleDrawer,
                    title: title,
                    showRefreshAction:
                        _selectedIndex == 0 || _selectedIndex == 1,
                    isMediumScreen: mediumScreen,
                    isConnected: _isConnected,
                  ),
                  Expanded(
                    child: pageContent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _onKeyHandler(node, event) {
    KeyEventResult result = KeyEventResult.ignored;

    for (final ShortcutActivator activator in _keyBindings.keys) {
      if (activator.accepts(event, RawKeyboard.instance)) {
        _keyBindings[activator]!.call();
        result = KeyEventResult.handled;
      }
    }

    return result;
  }
}
