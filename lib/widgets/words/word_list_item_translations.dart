import 'package:flutter/material.dart';

class WordListItemTranslations extends StatelessWidget {
  const WordListItemTranslations({
    Key? key,
    required List<String> translations,
  })  : _translations = translations,
        super(key: key);

  final List<String> _translations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _translations
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
