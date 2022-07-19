import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';
import 'package:lang_words/services/words_service.dart';

import '../../constants/sizes.dart';
import '../logo_text.dart';
import '../ui/icon_button_square.dart';
import '../words/edit_word.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required bool isMediumScreen,
    required bool showRefreshAction,
    required VoidCallback toggleDrawer,
    required String title,
    Key? key,
  })  : _isMediumScreen = isMediumScreen,
        _showRefreshAction = showRefreshAction,
        _toggleDrawer = toggleDrawer,
        _title = title,
        super(key: key);

  final bool _isMediumScreen;
  final bool _showRefreshAction;
  final VoidCallback _toggleDrawer;
  final String _title;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: Container(
        color: AppColors.bgHeader,
        height: kBottomNavigationBarHeight,
        child: Material(
          type: MaterialType.transparency,
          child: Row(
            children: [
              BurgerButton(toggleDrawer: _toggleDrawer),
              Padding(
                padding: const EdgeInsets.only(
                  left: Sizes.paddingBig,
                ),
                child: Text(
                  _title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: _isMediumScreen
                    ? Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Sizes.paddingBig,
                        ),
                        child: const LogoText(),
                      )
                    : const SizedBox(),
              ),
              if (_showRefreshAction)
                IconButtonSquare(
                  onTap: WordsService().fetchWords,
                  size: kBottomNavigationBarHeight,
                  icon: const Icon(Icons.refresh_outlined),
                ),
              IconButtonSquare(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const EditWord(),
                  );
                },
                size: kBottomNavigationBarHeight,
                icon: const Icon(Icons.add_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BurgerButton extends StatelessWidget {
  const BurgerButton({
    Key? key,
    required VoidCallback toggleDrawer,
  })  : _toggleDrawer = toggleDrawer,
        super(key: key);

  final VoidCallback _toggleDrawer;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleDrawer,
      child: Container(
        width: kBottomNavigationBarHeight,
        height: kBottomNavigationBarHeight,
        color: AppColors.reject,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // https://www.youtube.com/watch?v=l6Qrj3D79mQ
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 2500),
              tween: Tween(
                begin: 0.0,
                end: -pi / 4.0,
              ),
              builder: (context, value, child) => Transform.rotate(
                angle: value,
                child: Transform.scale(scaleX: value * 3 / pi, child: child!),
              ),
              child: _buildLine(),
            ),
            AnimatedOpacity(
              opacity: 0,
              duration: const Duration(milliseconds: 2500),
              child: _buildLine(),
            ),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 2500),
              tween: Tween(
                begin: 0.0,
                end: pi / 4.0,
              ),
              builder: (context, value, child) => Transform.rotate(
                angle: value,
                child: Transform.scale(scaleX: value * 3 / pi, child: child!),
              ),
              child: _buildLine(),
            ),
          ],
        ),
      ),
    );

    // return IconButtonSquare(
    //   onTap: _toggleDrawer,
    //   size: kBottomNavigationBarHeight,
    //   icon: const Icon(Icons.menu_outlined),
    // );
  }

  Container _buildLine() {
    return Container(
      height: 4,
      width: kBottomNavigationBarHeight * .75,
      color: AppColors.primary,
    );
  }
}
