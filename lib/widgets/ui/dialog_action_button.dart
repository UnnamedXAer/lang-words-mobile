import 'package:flutter/material.dart';

class DialogActionButton extends StatelessWidget {
  const DialogActionButton({
    super.key,
    required void Function()? onPressed,
    required String text,
    Color? textColor,
  })  : _onPressed = onPressed,
        _text = text,
        _textColor = textColor;

  final void Function()? _onPressed;
  final String _text;
  final Color? _textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: TextButton(
        onPressed: _onPressed,
        child: Text(
          _text,
          style: TextStyle(
            color: _textColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
