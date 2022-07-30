import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lang_words/widgets/layout/app_drawer.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../services/words_service.dart';
import '../../widgets/error_text.dart';
import '../../widgets/inherited/auth_state.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshWordsHandler());
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

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          if (widget._isKnownWords) {
            return WordsEmptyListInfo(
              key: const ValueKey('no words - known words'),
              text: 'There are not words mark as known yet :(.',
              actionText: 'Go to Words to learn.',
              action: () {
                if (AppDrawer.navKey.currentState?.mounted ?? false) {
                  AppDrawer.navKey.currentState!.widget.setSelectedIndex(0);
                }
              },
            );
          }

          return WordsEmptyListInfo(
            key: const ValueKey('no words - words'),
            text: 'No words found',
            actionText: 'Start adding words',
            action: () {
              showDialog(
                context: context,
                builder: (_) => const EditWord(),
              );
            },
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
    return Column(
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
                fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize),
          ),
        ),
      ],
    );
  }
}
