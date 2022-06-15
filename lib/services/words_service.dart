import 'dart:convert';
import 'dart:developer';

import '../dummy-data/lang-words-dummy-data.dart';
import '../models/word.dart';

class WordsService {
  Future<List<Word>> fetchWords(String userId) async {
    final data = await Future.value(WORDS)
        .then((value) => jsonDecode(value))
        .then((value) => value[userId]['words']) as Map<String, dynamic>;

    final List<Word> words = [];
    log(data.toString());

    data.forEach((key, value) {
      words.add(Word.fromFirebase(key, value));
    });

    return words;
  }
}
