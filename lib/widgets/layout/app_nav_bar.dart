import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';
import 'package:lang_words/services/words_service.dart';
import 'package:lang_words/widgets/layout/app_drawer.dart';
import 'package:lang_words/widgets/ui/spinner.dart';

import '../../constants/sizes.dart';
import '../inherited/auth_state.dart';
import '../logo_text.dart';
import '../ui/icon_button_square.dart';
import '../words/edit_word.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required bool isMediumScreen,
    required bool showRefreshAction,
    required VoidCallback toggleDrawer,
    required String title,
    required bool isConnected,
    Key? key,
  })  : _isMediumScreen = isMediumScreen,
        _showRefreshAction = showRefreshAction,
        _toggleDrawer = toggleDrawer,
        _title = title,
        _isConnected = isConnected,
        super(key: key);

  final bool _isMediumScreen;
  final bool _showRefreshAction;
  final VoidCallback _toggleDrawer;
  final String _title;
  final bool _isConnected;

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
              if (!_isConnected)
                const Icon(
                  Icons.signal_cellular_connected_no_internet_4_bar_outlined,
                  color: AppColors.textDarker,
                ),
              if (_showRefreshAction) const RefreshActionButton(),
              IconButtonSquare(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const EditWord(),
                  );
                },
                size: kBottomNavigationBarHeight,
                icon: const Icon(
                  Icons.add_outlined,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RefreshActionButton extends StatefulWidget {
  const RefreshActionButton({
    Key? key,
  }) : super(key: key);

  @override
  State<RefreshActionButton> createState() => _RefreshActionButtonState();
}

class _RefreshActionButtonState extends State<RefreshActionButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButtonSquare(
          onTap: () {
            setState(() {
              _isLoading = true;
            });
            final uid = AuthInfo.of(context).uid;
            WordsService().fetchWords(uid).then((value) {
              if (mounted) setState(() => _isLoading = false);
            });
          },
          size: kBottomNavigationBarHeight,
          icon: const Icon(
            Icons.refresh_outlined,
            color: AppColors.textDark,
          ),
        ),
        if (_isLoading)
          const Positioned(
            left: 0,
            child: Spinner(
              size: SpinnerSize.small,
            ),
          ),
      ],
    );
  }
}

class BurgerButton extends StatelessWidget {
  BurgerButton({
    Key? key,
    required VoidCallback toggleDrawer,
  })  : _toggleDrawer = toggleDrawer,
        super(key: key);

  final VoidCallback _toggleDrawer;
  final double _spacerSize = 7.0;
  final Animation<double> _animation = AppDrawer.animationController;

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
