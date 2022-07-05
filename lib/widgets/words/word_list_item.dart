import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';

import '../../constants/sizes.dart';
import '../../models/word.dart';
import '../../services/exception.dart';
import '../../services/words_service.dart';
import '../helpers/popups.dart';
import 'delete_word_dialog.dart';
import 'edit_word.dart';
import 'word_list_item_footer.dart';
import 'word_list_item_translations.dart';
import 'word_list_item_actions.dart';
import 'word_list_item_word.dart';

class WordListItem extends StatefulWidget {
  const WordListItem({
    required Word word,
    required Animation<double> animation,
    Key? key,
  })  : _word = word,
        _animation = animation,
        super(key: key);

  final Word _word;
  final Animation<double> _animation;

  @override
  State<WordListItem> createState() => _WordListItemState();
}

class _WordListItemState extends State<WordListItem> {
  final Map<String, bool> _loadingWords = {};

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: widget._animation,
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
                        WordListItemWord(word: widget._word.word),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          height: 1,
                          color: AppColors.border,
                        ),
                        WordListItemTranslations(word: widget._word),
                      ],
                    ),
                  ),
                ),
                WordListItemActions(
                  word: widget._word,
                  loading: _loadingWords[widget._word.id],
                  onEdit: _editHandler,
                  onDelete: _deleteActionHandler,
                  onToggleKnown: _toggleKnownHandler,
                  onAcknowledge: _acknowledgeHandler,
                ),
              ],
            ),
            WordListItemFooter(word: widget._word)
          ],
        ),
      ),
    );
  }

  void _editHandler() {
    showDialog(
      barrierColor: AppColors.bgBackdrop,
      context: context,
      builder: (_) => EditWord(word: widget._word),
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
          }, widget._word.id);
          Navigator.of(context, rootNavigator: true).maybePop();
        },
        onCancel: () => Navigator.of(context, rootNavigator: true).maybePop(),
      ),
    );
  }

  void _toggleKnownHandler() {
    _asyncAction(() {
      final ws = WordsService();
      return ws.toggleIsKnown(widget._word.id);
    }, widget._word.id);
  }

  void _acknowledgeHandler() {
    _asyncAction(() {
      final ws = WordsService();
      return ws.acknowledgeWord(widget._word.id);
    }, widget._word.id);
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
      _loadingWords.remove(wordId);
    });
  }
}
