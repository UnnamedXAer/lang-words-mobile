import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';

import '../../models/word.dart';

class WordListItem extends StatelessWidget {
  const WordListItem(this.word, {Key? key}) : super(key: key);

  final Word word;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Text(word.word),
    );
  }
}
