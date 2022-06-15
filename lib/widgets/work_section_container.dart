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
    final double margin = withMargin && bigScreen ? Sizes.padding : 0;

    return Container(
      width: bigScreen ? Sizes.maxWidth : double.infinity,
      alignment: Alignment.topCenter,
      margin: EdgeInsets.all(margin),
      padding: const EdgeInsets.symmetric(horizontal: Sizes.padding),
      decoration: BoxDecoration(
        border: withMargin
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
