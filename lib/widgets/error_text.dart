import 'package:flutter/material.dart';

class ErrorText extends StatelessWidget {
  const ErrorText(this.text, {Key? key}) : super(key: key);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).errorColor,
      ),
    );
  }
}
