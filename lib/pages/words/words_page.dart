import 'package:flutter/material.dart';

import '../../models/word.dart';
import '../../widgets/error_text.dart';
import '../../widgets/words/word_list_item.dart';

class WordsPage extends StatelessWidget {
  const WordsPage({
    Key? key,
    required bool fetching,
    required String? fetchError,
    required List<Word> words,
  })  : _fetching = fetching,
        _fetchError = fetchError,
        _words = words,
        super(key: key);

  final bool _fetching;
  final String? _fetchError;
  final List<Word> _words;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return _fetching
          ? const CircularProgressIndicator.adaptive()
          : _fetchError != null
              ? ErrorText(_fetchError!)
              : ListView.builder(
                  itemCount: _words.length,
                  itemBuilder: (context, index) {
                    return WordListItem(_words[index]);
                  },
                );
    });
  }
}
