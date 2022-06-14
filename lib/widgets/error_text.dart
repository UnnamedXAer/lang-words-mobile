import 'package:flutter/material.dart';

class ErrorText extends StatelessWidget {
  const ErrorText(this.text, {this.textAlign, Key? key}) : super(key: key);
  final String text;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        color: Theme.of(context).errorColor,
      ),
    );
  }
}
