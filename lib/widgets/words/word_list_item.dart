import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';

import '../../constants/sizes.dart';
import '../../models/word.dart';
import 'word_list_item_footer.dart';
import 'word_list_item_translations.dart';
import 'word_list_item_actions.dart';
import 'word_list_item_word.dart';

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
          const BoxShadow(
            color: Colors.black26,
            offset: Offset(
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
                      WordListItemWord(word: _word.word),
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
              WordListItemActions(word: _word),
            ],
          ),
          WordListItemFooter(word: _word)
        ],
      ),
    );
  }
}
