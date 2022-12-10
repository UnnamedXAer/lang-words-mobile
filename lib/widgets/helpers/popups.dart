import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';

import '../../constants/sizes.dart';

class PopupsHelper {
  static Future<T?> showSideSlideDialog<T extends Object?>({
    required BuildContext context,
    required Widget content,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: AppColors.bgBackdrop,
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> _,
        child,
      ) {
        final size = MediaQuery.of(context).size;
        final bigScreen = size.width >= Sizes.maxWidth;
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(
              (size.width * (bigScreen ? .5 : 1)) * (1 - animation.value),
              (-size.height * .25) * (1 - animation.value),
            ),
            child: Transform.scale(
              scale: animation.value,
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return content;
      },
    );
  }

  static Future<T?> showSideSlideDialogRich<T extends Object?>({
    required BuildContext context,
    String? title,
    required Widget content,
    EdgeInsetsGeometry? contentPadding,
    List<Widget>? actions,
    KeyEventResult Function(FocusNode, RawKeyEvent)? onKey,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: AppColors.bgBackdrop,
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> _,
        child,
      ) {
        final size = MediaQuery.of(context).size;
        final bigScreen = size.width >= Sizes.maxWidth;
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(
              (size.width * (bigScreen ? .5 : 1)) * (1 - animation.value),
              (-size.height * .25) * (1 - animation.value),
            ),
            child: Transform.scale(
              scale: animation.value,
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: GestureDetector(
              onTap: () {},
              child: Focus(
                onKey: onKey,
                child: AlertDialog(
                  contentPadding: contentPadding,
                  title: title != null ? Text(title) : null,
                  content: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 230,
                      maxHeight: 360,
                      maxWidth: 340,
                    ),
                    child: content,
                  ),
                  actions: actions,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showSnackbar({
    required BuildContext context,
    int durationMS = 4000,
    required Widget content,
    Color? backgroundColor,
    SnackBarBehavior? behavior = SnackBarBehavior.floating,
    ScaffoldMessengerState? scaffoldMessengerState,
  }) {
    final width = MediaQuery.of(context).size.width;

    return (scaffoldMessengerState ?? ScaffoldMessenger.of(context))
        .showSnackBar(
      SnackBar(
        width: width >= Sizes.minWidth ? Sizes.minWidth : null,
        margin: width >= Sizes.minWidth
            ? null
            : const EdgeInsets.symmetric(
                horizontal: Sizes.paddingBig,
                vertical: Sizes.paddingSmall,
              ),
        behavior: behavior,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.zero),
        ),
        backgroundColor: backgroundColor,
        content: content,
        duration: Duration(milliseconds: durationMS),
      ),
    );
  }
}
