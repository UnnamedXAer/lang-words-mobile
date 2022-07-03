import 'dart:convert';

import '../dummy-data/lang-words-dummy-data.dart';
import '../models/word.dart';
import 'exception.dart';

class WordsService {
  Future<List<Word>> fetchWords() async {
    // final data = await Future.value(WORDS)
    //         .then((value) => jsonDecode(value))
    //         .then((value) =>
    //             value[CURRENT_USER_ID]?['words'] ?? (<String, dynamic>{}))
    //     as Map<String, dynamic>;

    // final List<Word> words = [];

    // data.forEach((key, value) {
    //   words.add(Word.fromFirebase(key, value));
    // });

    if (WORDS.isEmpty) {
      (jsonDecode(WORDS_DATA)[CURRENT_USER_ID]?['words']
              as Map<String, dynamic>)
          .forEach((key, value) => WORDS.add(Word.fromFirebase(key, value)));
    }

    final List<Word> words = WORDS;

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

  Future<void> acknowledgeWord(String id) async {
    return tryCatch(() async {
      final idx = WORDS.indexWhere((x) => x.id == id);
      if (idx == -1) {
        throw NotFoundException('word ($id) does not exists anymore');
      }

      final word = WORDS[idx].copyWith(
        acknowledgesCnt: WORDS[idx].acknowledgesCnt + 1,
        lastAcknowledgeAt: DateTime.now(),
      );
    }, 'acknowledgeWord: id: $id');
  }

  Future<void> toggleIsKnown(String id) async {
    return tryCatch(() async {
      final idx = WORDS.indexWhere((x) => x.id == id);
      if (idx == -1) {
        throw NotFoundException('word ($id) does not exists anymore');
      }

      final wasKnown = WORDS[idx].known;

      final updatedWord = WORDS[idx].copyWith(
        known: !wasKnown,
        acknowledgesCnt: WORDS[idx].acknowledgesCnt + (wasKnown ? 0 : 1),
        lastAcknowledgeAt:
            wasKnown ? WORDS[idx].lastAcknowledgeAt : DateTime.now(),
      );

      WORDS[idx] = updatedWord;
    }, 'toggleIsKnown: id: $id');
  }

  Future<void> deleteWord(String id) async {
    return tryCatch(() async {
      WORDS.removeWhere((x) => x.id == id);
    }, 'deleteWord: id: $id');
  }

  Future<void> updateWord(
      {required String id, String? word, List<String>? translations}) async {
    return tryCatch(() async {
      final idx = WORDS.indexWhere((x) => x.id == id);
      if (idx == -1) {
        throw NotFoundException('word ($id) does not exists anymore');
      }

      final updatedWord = WORDS[idx].copyWith(
        word: word,
        translations: translations,
      );

      WORDS[idx] = updatedWord;
    }, 'updateWord: id: $id');
  }
}
