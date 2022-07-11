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
    return SelectableText(
      _translations.join('\n'),
      toolbarOptions: const ToolbarOptions(
        copy: true,
        selectAll: true,
        paste: false,
        cut: false,
      ),
      style: const TextStyle(
        fontSize: 16,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
