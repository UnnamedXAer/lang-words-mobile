import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lang_words/constants/colors.dart';

import '../../constants/sizes.dart';

class AppDrawer extends StatefulWidget {
  static final navKey = GlobalKey<_AppDrawerState>();

  const AppDrawer({
    required Widget drawerContent,
    required Widget page,
    Key? key,
  })  : _drawerContent = drawerContent,
        _page = page,
        super(key: key);

  final Widget _drawerContent;
  final Widget _page;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  double _maxSlide = 225.0;
  bool _canBeDragged = true;

  late final Map<ShortcutActivator, Function(FocusNode node)> _keyBindings = {
    LogicalKeySet(
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.tab,
    ): (FocusNode node) {
      final wasDismissed = _animationController.isDismissed;
      toggle();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (wasDismissed) {
          node.children.first.children.first.requestFocus();
        } else {
          // Get the Focus that wraps page content;
          // cannot use `traversalChildren` because it has set
          // `skipTraversal` to false.
          FocusNode child = node.children.elementAt(1);

          while (child.traversalChildren.isNotEmpty) {
            child = child.traversalChildren.first;
          }

          // should point at burger button
          child.requestFocus();
        }
      });
    },
    LogicalKeySet(
      LogicalKeyboardKey.escape,
    ): (_) {
      if (!_animationController.isDismissed) {
        toggle(false);
      }
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maxSlide =
        MediaQuery.of(context).size.width.clamp(0, Sizes.maxWidth) * 0.83;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggle([bool? open]) {
    final forward = open ?? _animationController.isDismissed;

    forward ? _animationController.forward() : _animationController.reverse();
  }

  void _onDragStart(DragStartDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;

    final minDragEdge = screenWidth * 0.4;

    bool isDragOpenFromLeft = _animationController.isDismissed &&
        details.globalPosition.dx < minDragEdge;
    bool isDragCloseFromRight = _animationController.isCompleted &&
        details.globalPosition.dx > minDragEdge;

    _canBeDragged = isDragOpenFromLeft || isDragCloseFromRight;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_canBeDragged) {
      final delta = ((details.primaryDelta ?? 0) / _maxSlide);
      _animationController.value += delta;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    _canBeDragged = false;
    if (_animationController.isDismissed || _animationController.isCompleted) {
      return;
    }

    if (details.velocity.pixelsPerSecond.dx.abs() >= 365.0) {
      final double visualVelocity = details.velocity.pixelsPerSecond.dx /
          MediaQuery.of(context).size.width;

      _animationController.fling(velocity: visualVelocity);
      return;
    }

    if (_animationController.value < 0.5) {
      toggle(false);
      return;
    }

    toggle(true);
  }

  void _onTap() {
    if (_animationController.isCompleted) {
      toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final mediumSize = screenSize.width >= Sizes.minWidth;

    return Focus(
      onFocusChange: (b) {
        log('main focus: get focus: $b');
        final currentlyFocused = FocusManager.instance.primaryFocus;
      },
      debugLabel: 'Focus - main wrapper',
      autofocus: false,
      canRequestFocus: false,
      skipTraversal: true,
      descendantsAreFocusable: true,
      descendantsAreTraversable: true,
      onKey: _onKeyHandler,
      child: GestureDetector(
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            final double scale = 1 - (0.33 * _animationController.value);
            final double slide = _maxSlide * _animationController.value;
            final double drawerScale =
                mediumSize ? 1 : 0.8 + (0.2 * _animationController.value);
            final double drawerSlide = mediumSize
                ? 0
                : -_maxSlide + _maxSlide * _animationController.value;

            return Stack(
              children: [
                Container(
                  color: AppColors.bgDrawer,
                  height: screenSize.height,
                  width: screenSize.width,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _maxSlide,
                    ),
                    child: SafeArea(
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translate(drawerSlide)
                          ..scale(drawerScale),
                        alignment: Alignment.centerLeft,
                        child: Focus(
                          debugLabel: 'Focus - Drawer Content',
                          canRequestFocus: !_animationController.isDismissed,
                          descendantsAreTraversable:
                              !_animationController.isDismissed,
                          descendantsAreFocusable:
                              !_animationController.isDismissed,
                          skipTraversal: true,
                          child: widget._drawerContent,
                        ),
                      ),
                    ),
                  ),
                ),
                Transform(
                  transform: Matrix4.identity()
                    ..translate(slide)
                    ..scale(scale),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.26),
                          offset: const Offset(
                            -6.0,
                            6.0,
                          ),
                          blurRadius: 15.0,
                        ),
                      ],
                    ),
                    child: Focus(
                      debugLabel: 'Focus - Page Content',
                      canRequestFocus: _animationController.isDismissed ||
                          _animationController.isAnimating,
                      descendantsAreTraversable:
                          _animationController.isDismissed ||
                              _animationController.isAnimating,
                      descendantsAreFocusable:
                          _animationController.isDismissed ||
                              _animationController.isAnimating,
                      skipTraversal: true,
                      child: widget._page,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  KeyEventResult _onKeyHandler(FocusNode node, RawKeyEvent event) {
    KeyEventResult result = KeyEventResult.ignored;

    for (final ShortcutActivator activator in _keyBindings.keys) {
      if (activator.accepts(event, RawKeyboard.instance)) {
        _keyBindings[activator]!.call(node);
        // node.children.first.requestFocus();
        result = KeyEventResult.handled;
      }
    }

    return result;
  }
}
