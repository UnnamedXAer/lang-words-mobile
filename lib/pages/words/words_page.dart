import 'dart:developer';

import 'package:flutter/material.dart';

import '../../constants/sizes.dart';
import '../../models/word.dart';
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
  List<Word> _words = [];
  String? _fetchError;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();

    _fetchMyWords();
  }

  @override
  Widget build(BuildContext context) {
    log('building ${widget._isKnownWords ? 'known-' : ''}words');

    return Builder(builder: (context) {
      if (_fetching) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }
      if (_fetchError != null) {
        return Center(child: ErrorText(_fetchError!));
      }
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: Sizes.paddingSmall),
        itemCount: _words.length,
        itemBuilder: (context, index) {
          return WordListItem(_words[index]);
        },
      );
    });
  }

  Future<void> _fetchMyWords() async {
    final ws = WordsService();
    _fetching = true;
    try {
      final userWords = await ws.fetchWords();
      _words = userWords;
    } catch (err) {
      _fetchError = (err as Error).toString();

      log('fetch words err: $err');
    } finally {
      setState(() {
        _fetching = false;
      });
    }
  }
}
