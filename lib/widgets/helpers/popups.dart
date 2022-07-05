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
}
