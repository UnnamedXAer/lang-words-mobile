import 'dart:io';

import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../models/word.dart';
import '../../services/exception.dart';
import '../../services/words_service.dart';
import '../helpers/popups.dart';
import 'delete_word_dialog.dart';
import 'edit_word.dart';
import 'word_list_item.dart';

class WordList extends StatefulWidget {
  const WordList({
    Key? key,
    required this.words,
  }) : super(key: key);
  final List<Word> words;

  @override
  State<WordList> createState() => _WordsLitState();
}

class _WordsLitState extends State<WordList> {
  final _listKey = GlobalKey<AnimatedListState>(debugLabel: 'words list key');
  final ScrollController _scrollController =
      ScrollController(debugLabel: 'words list scroll controller');

  final Map<String, bool> _loadingWords = {};

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility:
          !(Platform.isAndroid || Platform.isIOS || Platform.isFuchsia),
      radius: Radius.zero,
      controller: _scrollController,
      child: AnimatedList(
        key: _listKey,
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: Sizes.paddingSmall),
        initialItemCount: widget.words.length,
        itemBuilder: (context, index, anim) {
          final word = widget.words[index];
          return WordListItem(
            key: ValueKey(word.id),
            listKey: _listKey,
            animation: anim,
            word: word,
            loading: _loadingWords[word.id],
            onEdit: () => _editHandler(word),
            onDelete: () => _deleteActionHandler(word.id),
            onToggleKnown: () => _toggleKnownHandler(word.id),
            onAcknowledge: () => _acknowledgeHandler(word.id),
          );
        },
      ),
    );
  }

  void _editHandler(Word word) {
    showDialog(
      barrierColor: AppColors.bgBackdrop,
      context: context,
      builder: (_) => EditWord(word: word),
    );
  }

  Future<Object?> _deleteActionHandler<T extends Object?>(String id) {
    return PopupsHelper.showSideSlideDialog(
      context: context,
      content: DeleteDialog(
        word: id,
        onAccept: () {
          _asyncAction(() {
            final ws = WordsService();
            return ws.deleteWord(id);
          }, id);

          Navigator.of(context, rootNavigator: true).maybePop();
        },
        onCancel: () => Navigator.of(
          context,
          rootNavigator: true,
        ).maybePop(),
      ),
    );
  }

  void _toggleKnownHandler(String id) {
    _asyncAction(() {
      final ws = WordsService();
      return ws.toggleIsKnown(id);
    }, id);
  }

  void _acknowledgeHandler(String id) {
    _asyncAction(() {
      final ws = WordsService();
      return ws.acknowledgeWord(id);
    }, id);
  }

  void _asyncAction(
    Future<void> Function() actionFn,
    String wordId,
  ) async {
    setState(() {
      _loadingWords[wordId] = true;
    });
    String? failMessage;

    try {
      await Future.delayed(const Duration(milliseconds: 1510));
      await actionFn();
    } on NotFoundException {
      failMessage = 'This word does not exists anymore.';
    } on GenericException {
      failMessage = 'Sorry, action failed.';
    } catch (err) {
      failMessage = 'Sorry, action failed.';
    }

    if (mounted) {
      if (failMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failMessage),
            backgroundColor: Theme.of(context).errorColor,
          ),
        );
      }

      setState(() {
        _loadingWords.remove(wordId);
      });
    }
  }
}
