import 'dart:developer';

import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/exception.dart';
import '../../services/words_service.dart';
import '../ui/icon_button_square.dart';

class WordListItemActions extends StatefulWidget {
  const WordListItemActions({
    Key? key,
    required String wordId,
  })  : _id = wordId,
        super(key: key);

  final String _id;

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
              asyncAction(() {
                final ws = WordsService();
                return ws.updateWord(
                  id: widget._id,
                  word: "${widget._id} update",
                );
              });
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
                return ws.toggleIsKnown(widget._id);
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
                return ws.toggleIsKnown(widget._id);
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
                return ws.acknowledgeWord(widget._id);
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
    log('set isLoading ${widget._id}');
    try {
      await Future.delayed(const Duration(milliseconds: 3000));
      await actionFn();
    } on NotFoundException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This word does not exists anymore.',
          ),
        ),
      );
    } on GenericException {
      const SnackBar(
        content: Text(
          'Sorry, action failed.',
        ),
      );
    }

    log('reset isLoading ${widget._id}');

    setState(() {
      _isLoading = false;
    });
  }
}
