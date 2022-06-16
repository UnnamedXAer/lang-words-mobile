import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/sizes.dart';

class WorkSectionContainer extends StatelessWidget {
  const WorkSectionContainer(
      {required this.child, this.withMargin = true, Key? key})
      : super(key: key);

  final Widget child;
  final bool withMargin;

  @override
  Widget build(BuildContext context) {
    final bigScreen = MediaQuery.of(context).size.width >= Sizes.maxWidth;
    final double margin = withMargin ? Sizes.padding : 0;

    return Container(
      alignment: Alignment.topCenter,
      margin: EdgeInsets.all(margin),
      width: bigScreen ? Sizes.maxWidth : null, // double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Sizes.padding),
      decoration: BoxDecoration(
        border: withMargin || bigScreen
            ? Border.all(
                color: AppColors.border,
                width: 1,
              )
            : null,
        color: AppColors.bgWorkSection,
      ),
      child: child,
    );
  }
}
