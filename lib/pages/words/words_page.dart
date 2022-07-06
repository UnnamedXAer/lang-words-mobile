import 'dart:developer';

import 'package:flutter/material.dart';

import '../../constants/sizes.dart';
import '../../services/words_service.dart';
import '../../widgets/error_text.dart';
import '../../widgets/words/word_list.dart';

class WordsPage extends StatefulWidget {
  const WordsPage({
    Key? key,
    bool isKnownWords = false,
  })  : _isKnownWords = isKnownWords,
        super(key: key);

  final bool _isKnownWords;

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  final _listKey = GlobalKey<AnimatedListState>(debugLabel: 'words list key');
  late final Stream<WordsEvent> _wordsStream;

  // WordsEvent words = [];
  int _oldLen = 0;
  @override
  void initState() {
    super.initState();
    final ws = WordsService();
    log('setting up stream for WordsPage: ${widget._isKnownWords}');
    _wordsStream = ws.stream.asyncMap(
      (event) => event
          .where((element) => element.known == widget._isKnownWords)
          .toList(),
    );

    _wordsStream.listen((newWords) {
      if (newWords.length > _oldLen) {
        final int diff = newWords.length - _oldLen;
        for (int i = 0; i < diff; i++) {
          _listKey.currentState?.insertItem(
            i,
            duration: Duration(
              milliseconds: MediaQuery.of(context).size.width >=
                      Sizes.wordsActionsWrapPoint
                  ? 500
                  : 350,
            ),
          );
        }
      }
      _oldLen = newWords.length;
    });
    // _wordsStream.listen((newWords) {

    //   final List<Word> wordsList = newWords;

    //   if (_listKey.currentState != null &&
    //       _listKey.currentState!.widget.initialItemCount < wordsList.length) {
    //     List<Word> updateList =
    //         wordsList.where((e) => !words.contains(e)).toList();

    //     for (var update in updateList) {
    //       final int updateIndex = wordsList.indexOf(update);
    //       log('index of new word: $updateIndex');
    //       _listKey.currentState!
    //           .insertItem(updateIndex, duration: const Duration(seconds: 1));
    //     }
    //   }

    //   words = wordsList;
    // });
  }

  @override
  Widget build(BuildContext context) {
    log('building ${widget._isKnownWords ? 'known-' : ''}words');

    return StreamBuilder<WordsEvent>(
      stream: _wordsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (snapshot.hasError) {
          return Center(
            child: ErrorText(
              snapshot.error.toString(),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text(
              'No words found',
              textAlign: TextAlign.center,
            ),
          );
        }

        final words = snapshot.data!;
        return WordList(
          listKey: _listKey,
          words: words,
        );
      },
    );
  }
}
