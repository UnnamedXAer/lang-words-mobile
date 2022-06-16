import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';

import '../../models/word.dart';
import '../../services/words_service.dart';
import '../../widgets/error_text.dart';
import '../../widgets/words/word_list_item.dart';
import '../../widgets/work_section_container.dart';

class WordsPage extends StatefulWidget {
  static const routeName = '/words';
  const WordsPage({Key? key}) : super(key: key);

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
    return Scaffold(
      body: SafeArea(
        child: WorkSectionContainer(
          withMargin: false,
          child: Stack(
            // fit: StackFit.expand,
            alignment: AlignmentDirectional.topCenter,
            children: [
              Container(
                alignment: Alignment.topCenter,
                child: Container(
                  width: double.infinity,
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  height: kBottomNavigationBarHeight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('pop'),
                  ),
                ),
              ),
              Positioned.fill(
                top: kBottomNavigationBarHeight,
                child: _fetching
                    ? const CircularProgressIndicator.adaptive()
                    : _fetchError != null
                        ? ErrorText(_fetchError!)
                        : ListView.builder(
                            itemCount: _words.length,
                            itemBuilder: (context, index) {
                              return WordListItem(_words[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchMyWords() async {
    final ws = WordsService();
    _fetching = true;
    try {
      final userWords = await ws.fetchWords('GaKAjmdKPBaZcF3wwlfPJWXNtW63');
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
