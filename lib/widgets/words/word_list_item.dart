import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';
import 'package:lang_words/extensions/date_time.dart';

import '../../constants/sizes.dart';
import '../../models/word.dart';
import '../ui/icon_button_square.dart';

class WordListItem extends StatelessWidget {
  const WordListItem(Word word, {Key? key})
      : _word = word,
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
        border: Border.all(color: AppColors.border, width: 0.8),
        borderRadius: BorderRadius.circular(Sizes.smallRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.26),
            offset: const Offset(
              0.0,
              2.0,
            ),
            blurRadius: 5.0,
            spreadRadius: 0.0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(.16),
            offset: const Offset(
              0.0,
              2.0,
            ),
            blurRadius: 10.0,
            spreadRadius: 0.0,
          ),
          const BoxShadow(
            color: AppColors.bgWorkSection,
            offset: Offset(0.0, 0.0),
            blurRadius: 0.0,
            spreadRadius: 0.0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WordListItemWord(word: _word),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        height: 1,
                        color: AppColors.border,
                      ),
                      WordListItemTranslations(word: _word),
                    ],
                  ),
                ),
              ),
              const WordListItemActions(),
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
    return Material(
      type: MaterialType.transparency,
      child: Wrap(
        direction: direction,
        children: [
          IconButtonSquare(
            onTap: () {},
            icon: const Icon(
              Icons.edit_note_outlined,
              color: iconColor,
            ),
          ),
          IconButtonSquare(
            onTap: () {},
            icon: const Icon(
              Icons.delete_outline,
              color: iconColor,
            ),
          ),
          IconButtonSquare(
            onTap: () {},
            icon: const Icon(
              Icons.done_all_outlined,
              color: iconColor,
            ),
          ),
          IconButtonSquare(
            onTap: () {},
            icon: const Icon(
              Icons.done,
              color: iconColor,
            ),
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

class WordListItemWord extends StatelessWidget {
  const WordListItemWord({
    Key? key,
    required Word word,
  })  : _word = word,
        super(key: key);

  final Word _word;

  @override
  Widget build(BuildContext context) {
    return Text(
      _word.word,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
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
