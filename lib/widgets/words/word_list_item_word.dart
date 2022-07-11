import 'package:flutter/material.dart';

class WordListItemWord extends StatelessWidget {
  const WordListItemWord({
    Key? key,
    required String word,
  })  : _word = word,
        super(key: key);

  final String _word;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      _word,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
