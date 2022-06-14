import 'package:flutter/material.dart';

import '../constants/sizes.dart';
import 'work_section_container.dart';

class ScaffoldWithHorizontalStrollColumn extends StatelessWidget {
  const ScaffoldWithHorizontalStrollColumn(
      {required this.children, this.maxWidth = 300, Key? key})
      : super(key: key);
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WorkSectionContainer(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: Sizes.padding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
