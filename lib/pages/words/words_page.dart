import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import '../../constants/sizes.dart';
import '../../services/words_service.dart';
import '../../widgets/error_text.dart';
import '../../widgets/inherited/auth_state.dart';
import '../../widgets/ui/spinner.dart';
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
  late final StreamSubscription<WordsEvent> _wordsSubscription;

  int _oldLen = 0;
  @override
  void initState() {
    super.initState();

    final ws = WordsService();
    _wordsStream = ws.stream.asyncMap(
      (event) => event
          .where((element) => element.known == widget._isKnownWords)
          .toList(),
    );

    _wordsSubscription = _wordsStream.listen((newWords) {
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

    _wordsStream.handleError((error) {
      log('🚚🚚🚚🚚🚚 $error');
    });

    Future.delayed(Duration.zero, _refreshWordsHandler);
  }

  @override
  void dispose() {
    _wordsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WordsEvent>(
      stream: _wordsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return const Center(
            child: Spinner(
              size: SpinnerSize.large,
              showLabel: true,
            ),
          );
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
          onWordsRefresh: _refreshWordsHandler,
        );
      },
    );
  }

  Future<void> _refreshWordsHandler() {
    String? uid = AuthInfo.of(context).appUser?.uid;
    final ws = WordsService();
    return ws.fetchWords(uid);
  }
}
