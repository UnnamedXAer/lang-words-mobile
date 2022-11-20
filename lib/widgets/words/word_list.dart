import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../models/word.dart';
import '../../services/exception.dart';
import '../../services/words_service.dart';
import '../helpers/popups.dart';
import '../inherited/auth_state.dart';
import 'delete_word_dialog.dart';
import 'edit_word.dart';
import 'word_list_item.dart';

class WordList extends StatefulWidget {
  static int wordsKeyResetCnt = 0;
  static GlobalKey<AnimatedListState> wordsListKey =
      GlobalKey<AnimatedListState>(debugLabel: 'words list key, cnt: 0');
  static void resetWordsKey() {
    wordsListKey = GlobalKey<AnimatedListState>(
        debugLabel: 'words list key, cnt: ${++wordsKeyResetCnt}');
  }

  const WordList({
    Key? key,
    required this.words,
    required this.onWordsRefresh,
  }) : super(key: key);
  final List<Word> words;

  final Future<void> Function() onWordsRefresh;

  @override
  State<WordList> createState() => _WordsLitState();
}

class _WordsLitState extends State<WordList> {
  final ScrollController _scrollController =
      ScrollController(debugLabel: 'words list scroll controller');

  final Map<String, bool> _loadingWords = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listKey = WordList.wordsListKey;
    log('🏗️ building WordsList widget with key: $listKey');
    return Scrollbar(
      thumbVisibility:
          !(Platform.isAndroid || Platform.isIOS || Platform.isFuchsia),
      radius: Radius.zero,
      controller: _scrollController,
      child: RefreshIndicator(
        onRefresh: widget.onWordsRefresh,
        child: AnimatedList(
          key: listKey,
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: Sizes.paddingSmall),
          initialItemCount: widget.words.length,
          itemBuilder: (context, index, animation) {
            final word = widget.words[index];
            return WordListItem(
              key: ValueKey(word.id),
              animation: animation,
              word: word,
              loading: _loadingWords[word.id],
              onEdit: () => _editHandler(word),
              onDelete: () => _deleteActionHandler(word.firebaseId),
              onToggleKnown: () => _toggleKnownHandler(word.firebaseId),
              onAcknowledge: () => _acknowledgeHandler(word.firebaseId),
            );
          },
        ),
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

  Future<Object?> _deleteActionHandler<T extends Object?>(String firebaseId) {
    final index = widget.words.indexWhere((w) => w.firebaseId == firebaseId);
    final word = widget.words[index];
    return PopupsHelper.showSideSlideDialog(
      context: context,
      content: DeleteDialog(
        word: word.word,
        onAccept: () {
          _asyncAction(() async {
            final uid = AuthInfo.of(context).uid;

            final ws = WordsService();
            await ws.deleteWord(uid, word.id, firebaseId);
            _animateOutItem(index, word, AppColors.reject);
          }, firebaseId);

          Navigator.of(context, rootNavigator: true).maybePop();
        },
        onCancel: () => Navigator.of(
          context,
          rootNavigator: true,
        ).maybePop(),
      ),
    );
  }

  void _toggleKnownHandler(String firebaseId) {
    _asyncAction(() async {
      final uid = AuthInfo.of(context).uid;

      final index = widget.words.indexWhere((w) => w.firebaseId == firebaseId);
      final word = widget.words[index];
      final ws = WordsService();
      await ws.toggleIsKnown(uid, firebaseId);
      _animateOutItem(index, word, AppColors.primary);
    }, firebaseId);
  }

  void _acknowledgeHandler(String firebaseId) {
    final index = widget.words.indexWhere((w) => w.firebaseId == firebaseId);
    final word = widget.words[index];
    _animateOutItem(index, word, AppColors.primary);

    _asyncAction(() async {
      final uid = AuthInfo.of(context).uid;
      final ws = WordsService();
      await ws.acknowledgeWord(uid, firebaseId);
    }, firebaseId);
  }

  void _animateOutItem(int index, Word word, Color animationBgColor) {
    return WordList.wordsListKey.currentState!.removeItem(
      index,
      (context, animation) {
        return WordListItem(
          key: ValueKey(word.id),
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
      await actionFn();
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
