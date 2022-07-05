import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';

import '../../constants/sizes.dart';
import '../../models/word.dart';
import 'word_list_item_footer.dart';
import 'word_list_item_translations.dart';
import 'word_list_item_actions.dart';
import 'word_list_item_word.dart';

class WordListItem extends StatelessWidget {
  const WordListItem({
    required this.listKey,
    required this.animation,
    required this.word,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleKnown,
    required this.onAcknowledge,
    required this.loading,
    Key? key,
  }) : super(key: key);

  final Animation<double> animation;
  final GlobalKey<AnimatedListState> listKey;
  final Word word;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleKnown;
  final VoidCallback onAcknowledge;
  final bool? loading;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
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
                        WordListItemWord(word: word.word),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          height: 1,
                          color: AppColors.border,
                        ),
                        WordListItemTranslations(
                          translations: word.translations,
                        ),
                      ],
                    ),
                  ),
                ),
                WordListItemActions(
                  known: word.known,
                  loading: loading,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  onToggleKnown: onToggleKnown,
                  onAcknowledge: onAcknowledge,
                ),
              ],
            ),
            WordListItemFooter(word: word)
          ],
        ),
      ),
    );
  }
}
