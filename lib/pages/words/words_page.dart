import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../services/exception.dart';
import '../../services/words_service.dart';
import '../../widgets/error_text.dart';
import '../../widgets/inherited/auth_state.dart';
import '../../widgets/layout/app_drawer.dart';
import '../../widgets/ui/spinner.dart';
import '../../widgets/words/edit_word.dart';
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
  // final GlobalKey<AnimatedListState> _listKey =
  //     GlobalKey<AnimatedListState>(debugLabel: 'words list key');
  late final Stream<WordsEvent> _wordsStream;
  // late final StreamSubscription<WordsEvent> _wordsSubscription;

  // int _oldLen = 0;
  @override
  void initState() {
    super.initState();

    final ws = WordsService();
    _wordsStream = ws.stream.asyncMap(
      (event) => event
          .where((element) => element.known == widget._isKnownWords)
          .toList(),
    );

    // _wordsSubscription = _wordsStream.listen((newWords) {
    //   final int diff = newWords.length - _oldLen;
    //   if (WordList.wordsListKey.currentState != null && diff > 0) {
    //     log('🐝 inserting items: $diff');
    //     // here for inserting new item when user creates new word,
    //     // side effect is that on refresh when eg. we acknowledge some items
    //     // then now the first items on the list will unnecessary animate
    //     final duration = Duration(
    //       milliseconds:
    //           MediaQuery.of(context).size.width >= Sizes.wordsActionsWrapPoint
    //               // ? 500
    //               // : 350,
    //               ? 2500
    //               : 2500,
    //     );
    //     // we should find the differences and animate corresponding items instead of
    //     // the first ones
    //     for (int i = 0; i < diff; i++) {
    //       WordList.wordsListKey.currentState!.insertItem(
    //         i,
    //         duration: duration,
    //       );
    //     }
    //   }
    //   _oldLen = newWords.length;
    // }, onError: (err) {
    //   log('_WordsPageState: initState: listen: err: $err');
    // });

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _refreshWordsHandler(true));
  }

  @override
  void dispose() {
    // _wordsSubscription.cancel();
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
          String msg;

          switch (snapshot.error.runtimeType) {
            case AppException:
              msg = (snapshot.error as AppException).message;
              break;
            default:
              msg = GenericException(snapshot.error).message;
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Sizes.paddingBig),
              child: ErrorText(
                msg,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
          if (widget._isKnownWords) {
            return WordsEmptyListInfo(
              key: const ValueKey('no words - known words'),
              text: 'You have no words marked as known yet :(.',
              actionText: 'Go to Words to learn.',
              action: () {
                if (AppDrawer.navKey.currentState?.mounted ?? false) {
                  AppDrawer.navKey.currentState!.widget.setSelectedIndex(0);
                }
              },
            );
          }
          final ws = WordsService();
          return WordsEmptyListInfo(
            key: const ValueKey('no words - words'),
            text: ws.initWordsLength == 0
                ? ws.initKnownWordsLength == 0
                    ? 'No words found 😟'
                    : 'You have no new words.'
                : 'Great! You acknowledged all words!',
            actionText: ws.initWordsLength == 0
                ? 'Start adding words'
                : 'Refresh to start again',
            action: ws.initWordsLength == 0
                ? () {
                    showDialog(
                      context: context,
                      builder: (_) => const EditWord(),
                    );
                  }
                : _refreshWordsHandler,
          );
        }

        final words = snapshot.data!;
        return WordList(
          // listKey: WordList.wordsListKey,
          words: words,
          onWordsRefresh: _refreshWordsHandler,
        );
      },
    );
  }

  Future<void> _refreshWordsHandler([bool canSkipRefetching = false]) {
    final appUser = AuthInfo.of(context).appUser;
    final ws = WordsService();

    return ws.refreshWordsList(appUser!.uid, canSkipRefetching);
  }
}

class WordsEmptyListInfo extends StatelessWidget {
  const WordsEmptyListInfo({
    Key? key,
    required this.text,
    required this.actionText,
    required this.action,
  }) : super(key: key);

  final String text;
  final String actionText;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sizes.paddingBig),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(color: AppColors.textDark),
          ),
          TextButton(
            onPressed: action,
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
