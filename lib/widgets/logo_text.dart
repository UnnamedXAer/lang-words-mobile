import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';

class LogoText extends StatelessWidget {
  const LogoText({this.fontSize = 32, Key? key}) : super(key: key);

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Lang Words',
      style: TextStyle(
        fontFeatures: const [FontFeature.enable('smcp')],
        color: AppColors.primary,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
