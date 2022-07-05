import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../models/word.dart';
import '../../services/exception.dart';
import '../../services/words_service.dart';
import '../helpers/popups.dart';
import '../ui/icon_button_square.dart';
import 'delete_word_dialog.dart';
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
                barrierColor: AppColors.bgBackdrop,
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
            onTap: _deleteActionHandler,
            isLoading: _isLoading,
            icon: const Icon(
              Icons.delete_outline,
              color: iconColor,
            ),
          ),
          IconButtonSquare(
            onTap: () {
              _asyncAction(() {
                final ws = WordsService();
                return ws.toggleIsKnown(widget._word.id);
              });
            },
            isLoading: _isLoading,
            icon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.done_all_outlined,
                  color: iconColor,
                ),
                if (widget._word.known)
                  const Positioned(
                    bottom: 10,
                    right: 10,
                    child: Icon(
                      Icons.close_outlined,
                      color: iconColor,
                      size: 12,
                    ),
                  )
              ],
            ),
          ),
          if (!widget._word.known)
            IconButtonSquare(
              onTap: () {
                _asyncAction(() {
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

  Future<Object?> _deleteActionHandler<T extends Object?>() {
    return PopupsHelper.showSideSlideDialog(
      context: context,
      content: DeleteDialog(
        word: widget._word.word,
        onAccept: () {
          _asyncAction(() {
            final ws = WordsService();
            return ws.deleteWord(widget._word.id);
          });
          Navigator.of(context, rootNavigator: true).maybePop();
        },
        onCancel: Navigator.of(context, rootNavigator: true).maybePop,
      ),
    );
  }

  void _asyncAction(Future<void> Function() actionFn) async {
    setState(() {
      _isLoading = true;
    });
    String? failMessage;
    try {
      await Future.delayed(const Duration(milliseconds: 1150));
      await actionFn();
    } on NotFoundException {
      failMessage = 'This word does not exists anymore.';
    } on GenericException {
      failMessage = 'Sorry, action failed.';
    } catch (err) {
      failMessage = 'Sorry, action failed.';
    }

    if (mounted && failMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failMessage),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
}
