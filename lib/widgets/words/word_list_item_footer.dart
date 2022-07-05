import 'package:flutter/material.dart';
import 'package:lang_words/extensions/date_time.dart';

import '../../models/word.dart';

class WordListItemFooter extends StatelessWidget {
  const WordListItemFooter({
    Key? key,
    required Word word,
  })  : _word = word,
        super(key: key);

  final Word _word;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.secondary,
    );
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        children: [
          Text('Added at: ${_word.createAt.format()}', style: textStyle),
          Text(
            'Acknowledges count: ${_word.acknowledgesCnt}',
            style: textStyle,
          ),
          if (_word.lastAcknowledgeAt != null)
            Text(
              'Last acknowledged at: ${_word.lastAcknowledgeAt!.format()}',
              style: textStyle,
            ),
        ],
      ),
    );
  }
}
