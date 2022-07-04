import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../models/word.dart';
import '../../services/exception.dart';
import '../../services/words_service.dart';
import '../ui/icon_button_square.dart';
import 'edit_word.dart';

class WordListItemActions extends StatefulWidget {
  const WordListItemActions({
    Key? key,
    required Word word,
  })  : _word = word,
        super(key: key);

  final Word _word;

  @override
  State<WordListItemActions> createState() => _WordListItemActionsState();
}

class _WordListItemActionsState extends State<WordListItemActions> {
  bool _isLoading = false;

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
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => EditWord(word: widget._word),
              );
            },
            isLoading: _isLoading,
            icon: const Icon(
              Icons.edit_note_outlined,
              color: iconColor,
            ),
          ),
          IconButtonSquare(
            onTap: () {
              asyncAction(() {
                final ws = WordsService();
                return ws.toggleIsKnown(widget._word.id);
              });
            },
            isLoading: _isLoading,
            icon: const Icon(
              Icons.delete_outline,
              color: iconColor,
            ),
          ),
          IconButtonSquare(
            onTap: () {
              asyncAction(() {
                final ws = WordsService();
                return ws.toggleIsKnown(widget._word.id);
              });
            },
            isLoading: _isLoading,
            icon: const Icon(
              Icons.done_all_outlined,
              color: iconColor,
            ),
          ),
          IconButtonSquare(
            onTap: () {
              asyncAction(() {
                final ws = WordsService();
                return ws.acknowledgeWord(widget._word.id);
              });
            },
            isLoading: _isLoading,
            icon: const Icon(
              Icons.done,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  void asyncAction(Future<void> Function() actionFn) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      await actionFn();
    } on NotFoundException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'This word does not exists anymore.',
          ),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    } on GenericException {
      SnackBar(
        content: const Text(
          'Sorry, action failed.',
        ),
        backgroundColor: Theme.of(context).errorColor,
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
}
