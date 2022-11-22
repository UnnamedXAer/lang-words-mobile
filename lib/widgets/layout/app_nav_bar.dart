import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';
import 'package:lang_words/services/words_service.dart';
import 'package:lang_words/widgets/layout/app_drawer.dart';
import 'package:lang_words/widgets/ui/spinner.dart';
import 'package:lang_words/widgets/words/word_list.dart';

import '../../constants/sizes.dart';
import '../inherited/auth_state.dart';
import '../logo_text.dart';
import '../ui/icon_button_square.dart';
import '../words/edit_word.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required bool isMediumScreen,
    required bool dense,
    required bool showWordsActions,
    required VoidCallback toggleDrawer,
    required String title,
    required bool isConnected,
    required bool isSyncing,
    required VoidCallback onSyncTap,
    required bool anyPendingSyncExit,
    Key? key,
  })  : _isMediumScreen = isMediumScreen,
        _dense = dense,
        _showWordsActions = showWordsActions,
        _toggleDrawer = toggleDrawer,
        _title = title,
        _isConnected = isConnected,
        _isSyncing = isSyncing,
        _onSyncTap = onSyncTap,
        _anyPendingSyncExit = anyPendingSyncExit,
        super(key: key);

  final bool _isMediumScreen;
  final bool _dense;
  final bool _showWordsActions;
  final VoidCallback _toggleDrawer;
  final String _title;
  final bool _isConnected;
  final bool _isSyncing;
  final VoidCallback _onSyncTap;
  final bool _anyPendingSyncExit;

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
              _BurgerButton(
                toggleDrawer: _toggleDrawer,
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: _dense ? Sizes.paddingSmall : Sizes.paddingBig,
                ),
                child: Text(
                  _title,
                  style: _dense
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge,
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
              if (!_isConnected || _showWordsActions)
                _SyncActionButton(
                  isConnected: _isConnected,
                  onSyncTap: _onSyncTap,
                  isSyncing: _isSyncing,
                  anyPendingSyncExit: _anyPendingSyncExit,
                ),
              if (_showWordsActions)
                _RefreshActionButton(
                  disabled: _isSyncing,
                ),
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

class _SyncActionButton extends StatelessWidget {
  const _SyncActionButton({
    Key? key,
    required bool isConnected,
    required VoidCallback onSyncTap,
    required bool isSyncing,
    required bool anyPendingSyncExit,
  })  : _isConnected = isConnected,
        _onSyncTap = onSyncTap,
        _isSyncing = isSyncing,
        _anyPendingSyncExit = anyPendingSyncExit,
        super(key: key);

  final bool _isConnected;
  final VoidCallback _onSyncTap;
  final bool _isSyncing;
  final bool _anyPendingSyncExit;

  @override
  Widget build(BuildContext context) {
    return IconButtonSquare(
      onTap: _isConnected ? _onSyncTap : null,
      isLoading: _isSyncing,
      size: kBottomNavigationBarHeight,
      icon: (_isConnected)
          ? Stack(
              children: [
                const Positioned.fill(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Icon(
                      Icons.sync_alt_outlined,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                if (_anyPendingSyncExit)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
              ],
            )
          : const Icon(
              Icons.signal_cellular_connected_no_internet_4_bar_outlined,
              color: AppColors.textDarker,
            ),
    );
  }
}

class _RefreshActionButton extends StatefulWidget {
  const _RefreshActionButton({
    this.disabled = false,
    Key? key,
  }) : super(key: key);

  final bool disabled;

  @override
  State<_RefreshActionButton> createState() => _RefreshActionButtonState();
}

class _RefreshActionButtonState extends State<_RefreshActionButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButtonSquare(
          onTap: widget.disabled
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                  });
                  final uid = AuthInfo.of(context).uid;
                  await WordsService().refreshWordsList(uid);
                  WordList.resetWordsKey();
                  if (mounted) setState(() => _isLoading = false);
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

class _BurgerButton extends StatelessWidget {
  _BurgerButton({
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
