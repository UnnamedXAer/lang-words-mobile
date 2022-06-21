import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';

import '../../constants/sizes.dart';
import '../../dummy-data/lang-words-dummy-data.dart';
import '../../models/word.dart';

class WordListItem extends StatelessWidget {
  WordListItem(Word word, {Key? key})
      : _word = WORD,
        super(key: key);

  final Word _word;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        top: Sizes.paddingSmall,
        left: Sizes.paddingSmall,
        right: Sizes.paddingSmall,
      ),
      padding: const EdgeInsets.only(
        top: Sizes.paddingBig,
        left: Sizes.paddingBig,
        right: Sizes.paddingBig,
        bottom: 0,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.border,
        ),
        borderRadius: BorderRadius.circular(Sizes.smallRadius),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  child: Column(
                    children: [
                      WordListItemWord(word: _word),
                      WordListItemTranslations(word: _word),
                    ],
                  ),
                ),
              ),
              WordListItemActions(),
            ],
          ),
          WordListItemFooter(word: _word)
        ],
      ),
    );
  }
}

class WordListItemActions extends StatelessWidget {
  const WordListItemActions({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final direction = MediaQuery.of(context).size.width > 950
        ? Axis.horizontal
        : Axis.vertical;

    const iconColor = AppColors.textDark;
    return Container(
      child: Wrap(
        direction: direction,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_note_outlined),
            color: iconColor,
            focusColor: Colors.red,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.delete_outline),
            focusColor: Colors.red,
            color: iconColor,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.done_all_outlined),
            color: iconColor,
            focusColor: Colors.red,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.done),
            focusColor: Colors.red,
            color: iconColor,
          ),
        ],
      ),
    );
  }
}

class WordListItemTranslations extends StatelessWidget {
  const WordListItemTranslations({
    Key? key,
    required Word word,
  })  : _word = word,
        super(key: key);

  final Word _word;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: _word.translations.map((e) => Text(e)).toList(),
      ),
    );
  }
}

class WordListItemWord extends StatelessWidget {
  const WordListItemWord({
    Key? key,
    required Word word,
  })  : _word = word,
        super(key: key);

  final Word _word;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(_word.word),
    );
  }
}

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
          Text('Added at: ${_word.createAt}', style: textStyle),
          Text(
            'Acknowledges count: ${_word.acknowledgesCnt}',
            style: textStyle,
          ),
          Text(
            'Last acknowledged at ${_word.lastAcknowledgeAt}',
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
