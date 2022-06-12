import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/sizes.dart';

class WorkSectionContainer extends StatelessWidget {
  const WorkSectionContainer({required this.child, Key? key}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        alignment: Alignment.topCenter,
        margin: const EdgeInsets.all(Sizes.padding),
        padding: const EdgeInsets.symmetric(horizontal: Sizes.padding),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          color: AppColors.bgWorkSection,
        ),
        child: child,
      ),
    );
  }
}
