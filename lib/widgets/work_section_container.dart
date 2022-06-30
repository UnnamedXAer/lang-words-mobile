import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/sizes.dart';

class WorkSectionContainer extends StatelessWidget {
  const WorkSectionContainer({
    required this.child,
    this.withMargin = true,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final bool withMargin;

  @override
  Widget build(BuildContext context) {
    final bigScreen = MediaQuery.of(context).size.width >= Sizes.maxWidth;

    return Container(
      alignment: Alignment.topCenter,
      margin: withMargin ? const EdgeInsets.all(Sizes.padding) : null,
      decoration: BoxDecoration(
        color: AppColors.bgWorkSection,
        border: withMargin || bigScreen
            ? Border.all(
                color: AppColors.border,
                width: 1,
              )
            : null,
      ),
      child: child,
    );
  }
}
