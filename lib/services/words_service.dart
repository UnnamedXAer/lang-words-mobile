import 'dart:convert';

import '../dummy-data/lang-words-dummy-data.dart';
import '../models/word.dart';

class WordsService {
  Future<List<Word>> fetchWords() async {
    final data = await Future.value(WORDS)
            .then((value) => jsonDecode(value))
            .then((value) =>
                value[CURRENT_USER_ID]?['words'] ?? (<String, dynamic>{}))
        as Map<String, dynamic>;

    final List<Word> words = [];

    data.forEach((key, value) {
      words.add(Word.fromFirebase(key, value));
    });

    return words;
  }

  Future<void> addWord(String word, List<String> translations) async {
    //
  }

  Future<bool> checkIfWordExists(String word) async {
    final wordLowercased = word.toLowerCase();
    final words = await fetchWords();
    return words.any((element) => element.word.toLowerCase() == wordLowercased);
  }
}
