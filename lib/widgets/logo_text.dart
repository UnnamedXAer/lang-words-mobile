import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';

class LogoText extends StatelessWidget {
  const LogoText({this.fontSize = 34, Key? key}) : super(key: key);

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      textAlign: TextAlign.center,
      style: const TextStyle(
        letterSpacing: 10,
      ),
      TextSpan(
          text: 'L',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(
              text: 'ANG ',
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: fontSize * .65,
              ),
            ),
            const TextSpan(text: 'W'),
            TextSpan(
              text: 'ORDS',
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: fontSize * .65,
              ),
            )
          ]),
    );
  }
}
