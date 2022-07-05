import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../constants/sizes.dart';
import '../../services/words_service.dart';
import '../../widgets/error_text.dart';
import '../../widgets/words/word_list_item.dart';

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
  late final Stream<WordsEvent> _wordsStream;
  final ScrollController _scrollController =
      ScrollController(debugLabel: 'words list scroll controller');

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
        return Scrollbar(
          thumbVisibility:
              !(Platform.isAndroid || Platform.isIOS || Platform.isFuchsia),
          radius: Radius.zero,
          controller: _scrollController,
          child: AnimatedList(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: Sizes.paddingSmall),
            initialItemCount: words.length,
            itemBuilder: (context, index, anim) {
              return WordListItem(
                key: ValueKey(words[index].id),
                word: words[index],
                animation: anim,
              );
            },
          ),
        );
      },
    );
  }
}
