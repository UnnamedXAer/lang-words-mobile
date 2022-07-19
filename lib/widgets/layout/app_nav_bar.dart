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

class BurgerButton extends StatefulWidget {
  const BurgerButton({
    Key? key,
    required VoidCallback toggleDrawer,
  })  : _toggleDrawer = toggleDrawer,
        super(key: key);

  final VoidCallback _toggleDrawer;

  @override
  State<BurgerButton> createState() => _BurgerButtonState();
}

class _BurgerButtonState extends State<BurgerButton> {
  final double _spacerSize = 7.0;
  double rotateValue = 0;
  double bottomRotate = 0;
  double translateXMiddleLine = 0;
  double middleLineOpacity = 1;
  bool isDismissed = true;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget._toggleDrawer();
        setState(() {
          rotateValue = isDismissed ? (-pi / 4.0) : 0;
          bottomRotate = isDismissed ? (pi / 4.0) : 0;
          translateXMiddleLine =
              isDismissed ? kBottomNavigationBarHeight * 0.7 : 0;
          middleLineOpacity = isDismissed ? 0 : 1;

          isDismissed = !isDismissed;
        });
      },
      child: Container(
        width: kBottomNavigationBarHeight,
        height: kBottomNavigationBarHeight,
        alignment: Alignment.center,
        child: Container(
          // color: Colors.green,
          width: kBottomNavigationBarHeight * .5,
          height: 3 * 3 + 2 * _spacerSize,
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // https://www.youtube.com/watch?v=l6Qrj3D79mQ
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                tween: Tween(
                  begin: 0.0,
                  end: rotateValue,
                ),
                builder: (context, value, child) => Transform.rotate(
                  alignment: Alignment.centerRight,
                  angle: value,
                  child: child!,
                ),
                child: _buildLine(),
              ),
              SizedBox(height: _spacerSize),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween<double>(begin: 0.0, end: translateXMiddleLine),
                builder: (_, value, child) => Transform.translate(
                  offset: Offset(value, 0),
                  child: child!,
                ),
                child: AnimatedOpacity(
                  opacity: middleLineOpacity,
                  duration: const Duration(milliseconds: 300),
                  child: _buildLine(),
                ),
              ),
              SizedBox(height: _spacerSize),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                tween: Tween(
                  begin: 0.0,
                  end: bottomRotate,
                ),
                builder: (context, value, child) => Transform.rotate(
                  alignment: Alignment.centerRight,
                  angle: value,
                  child: child!,
                ),
                child: _buildLine(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container _buildLine() {
    return Container(
      height: 3,
      width: kBottomNavigationBarHeight * .6,
      color: AppColors.textDark,
    );
  }
}
