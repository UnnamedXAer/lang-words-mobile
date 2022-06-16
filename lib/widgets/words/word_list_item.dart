import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';

import '../../constants/sizes.dart';
import '../../models/word.dart';

class WordListItem extends StatelessWidget {
  const WordListItem(this.word, {Key? key}) : super(key: key);

  final Word word;

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
      child: Column(children: [
        Row(
          children: [
            Container(
              child: Column(),
            ),
          ],
        )
      ]),
    );
  }
}
