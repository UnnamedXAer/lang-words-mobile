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
    required this.listKey,
    required this.words,
  }) : super(key: key);
  final List<Word> words;

  final GlobalKey<AnimatedListState> listKey;

  @override
  State<WordList> createState() => _WordsLitState();
}

class _WordsLitState extends State<WordList> {
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
        key: widget.listKey,
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: Sizes.paddingSmall),
        initialItemCount: widget.words.length,
        itemBuilder: (context, index, animation) {
          final word = widget.words[index];
          return WordListItem(
            key: ValueKey(word.id),
            listKey: widget.listKey,
            animation: animation,
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
    final index = widget.words.indexWhere((w) => w.id == id);
    final word = widget.words[index];
    return PopupsHelper.showSideSlideDialog(
      context: context,
      content: DeleteDialog(
        word: word.word,
        onAccept: () {
          _asyncAction(() async {
            final ws = WordsService();
            await ws.deleteWord(id);
            _animateOutItem(index, word, AppColors.reject);
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
    _asyncAction(() async {
      final index = widget.words.indexWhere((w) => w.id == id);
      final word = widget.words[index];
      final ws = WordsService();
      await ws.toggleIsKnown(id);
      _animateOutItem(index, word, AppColors.primary);
    }, id);
  }

  void _acknowledgeHandler(String id) {
    _asyncAction(() async {
      final index = widget.words.indexWhere((w) => w.id == id);
      final word = widget.words[index];
      final ws = WordsService();
      await ws.acknowledgeWord(id);

      _animateOutItem(index, word, AppColors.primary);
    }, id);
  }

  void _animateOutItem(int index, Word word, Color animationBgColor) {
    return widget.listKey.currentState!.removeItem(
      index,
      (context, animation) {
        return WordListItem(
          key: ValueKey(word.id),
          listKey: widget.listKey,
          animation: animation,
          word: word,
          loading: false,
          onEdit: () {},
          onDelete: () {},
          onToggleKnown: () {},
          onAcknowledge: () {},
          color: animationBgColor.withOpacity(0.5),
        );
      },
      duration: Duration(
        milliseconds:
            MediaQuery.of(context).size.width >= Sizes.wordsActionsWrapPoint
                ? 500
                : 350,
      ),
    );
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
      await Future.delayed(const Duration(milliseconds: 110));
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
