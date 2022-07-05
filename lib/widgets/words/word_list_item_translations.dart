import 'package:flutter/material.dart';

import '../../models/word.dart';

class WordListItemTranslations extends StatelessWidget {
  const WordListItemTranslations({
    Key? key,
    required Word word,
  })  : _word = word,
        super(key: key);

  final Word _word;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _word.translations
          .map(
            (translation) => Text(
              translation,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
          .toList(),
    );
  }
}
