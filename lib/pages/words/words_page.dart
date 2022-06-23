import 'package:flutter/material.dart';

import '../../constants/sizes.dart';
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
      if (_fetching) {
        return const CircularProgressIndicator.adaptive();
      }
      if (_fetchError != null) {
        return ErrorText(_fetchError!);
      }
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: Sizes.paddingSmall),
        itemCount: _words.length,
        itemBuilder: (context, index) {
          return WordListItem(_words[index]);
        },
      );
    });
  }
}
