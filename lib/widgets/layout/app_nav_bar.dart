import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';
import 'package:lang_words/services/words_service.dart';

import '../../constants/sizes.dart';
import '../logo_text.dart';
import '../ui/icon_button_square.dart';
import '../words/edit_word.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required Animation<double> animation,
    required bool isMediumScreen,
    required bool showRefreshAction,
    required VoidCallback toggleDrawer,
    required String title,
    Key? key,
  })  : _animation = animation,
        _isMediumScreen = isMediumScreen,
        _showRefreshAction = showRefreshAction,
        _toggleDrawer = toggleDrawer,
        _title = title,
        super(key: key);

  final Animation<double> _animation;
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
              BurgerButton(
                animation: _animation,
                toggleDrawer: _toggleDrawer,
              ),
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
    required Animation<double> animation,
    required VoidCallback toggleDrawer,
  })  : _animation = animation,
        _toggleDrawer = toggleDrawer,
        super(key: key);

  final Animation<double> _animation;
  final VoidCallback _toggleDrawer;
  final double _spacerSize = 7.0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleDrawer,
      child: SizedBox(
        width: kBottomNavigationBarHeight,
        height: kBottomNavigationBarHeight,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (_, child) {
            // TODO: check if animation can be a global value notifier
            final rotation = (_animation.value * 0.63);
            return Transform.translate(
              offset: Offset(-3.5 * _animation.value, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.rotate(
                    alignment: Alignment.centerRight,
                    angle: -rotation,
                    child: child!,
                  ),
                  SizedBox(height: _spacerSize),
                  Transform.translate(
                    offset: Offset(
                      kBottomNavigationBarHeight * 0.7 * _animation.value,
                      0,
                    ),
                    child: Opacity(
                      opacity: (1 - _animation.value * 1.5).clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                  SizedBox(height: _spacerSize),
                  Transform.rotate(
                    alignment: Alignment.centerRight,
                    angle: rotation,
                    child: child,
                  ),
                ],
              ),
            );
          },
          child: Container(
            height: 3,
            width: kBottomNavigationBarHeight * .6,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
