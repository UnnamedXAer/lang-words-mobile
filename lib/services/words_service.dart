import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_database/firebase_database.dart';

import '../dummy-data/lang-words-dummy-data.dart';
import '../models/word.dart';
import 'exception.dart';

typedef WordsEvent = List<Word>;

class WordsService {
  static final WordsService _instance = WordsService._internal();
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  final List<Word> _words = [];
  final _streamController = StreamController<WordsEvent>();
  late final Stream<WordsEvent> _stream =
      _streamController.stream.asBroadcastStream();
  var __dev_reemmit = false;
  Stream<WordsEvent> get stream {
    if (!__dev_reemmit) {
      __dev_reemmit = true;
    } else {
      _emit();
    }

    return _stream;
  }

  factory WordsService() {
    return _instance;
  }

  // named constructor
  WordsService._internal() {
    Future.delayed(const Duration(milliseconds: 150), () async {
      await fetchWords();
      log('pushing words ${_words.length}');
    });
  }

  void _emit() => _streamController.add(_words);

  Future<void> fetchWords() async {
    final ref = _database.ref('$CURRENT_USER_ID/words');
    final wordsSnapshot = await ref.get();

    if (!wordsSnapshot.exists) {
      _streamController.addError(NotFoundException('user words not found'));
      return;
    }

    final words = <Word>[];
    (wordsSnapshot.value as Map<dynamic, dynamic>).forEach(
      (key, value) {
        // https://stackoverflow.com/questions/70595225/cant-cast-internallinkedhashmapobject-object-to-anything
        log('$key --->\n$value');
        words.add(
          Word.fromFirebase(
            key,
            value,
          ),
        );
      },
    );

    _words.clear();
    _words.addAll(words);
    await Future.delayed(const Duration(milliseconds: 50));
    _emit();
  }

  Future<String> addWord(String word, List<String> translations) async {
    final newWord = Word(
      id: DateTime.now().toString(),
      word: word,
      translations: [...translations],
      createAt: DateTime.now(),
      lastAcknowledgeAt: null,
      acknowledgesCnt: 0,
      known: false,
    );

    WORDS.insert(0, newWord);
    _words.insert(0, newWord);
    _emit();

    return newWord.id;
  }

  /// Checks whether given string - `word` already exists in current user's words
  ///
  /// If `id` is not null it will ignore record with given id.
  Future<bool> checkIfWordExists(String word, {String? id}) async {
    final wordLowercased = word.toLowerCase();

    return WORDS
        .any((x) => x.word.toLowerCase() == wordLowercased && x.id != id);
  }

  Future<void> acknowledgeWord(String id) async {
    return tryCatch(() async {
      final idx = _words.indexWhere((x) => x.id == id);
      if (idx == -1) {
        throw NotFoundException('word ($id) does not exists anymore');
      }

      final updatedWord = _words[idx].copyWith(
        acknowledgesCnt: _words[idx].acknowledgesCnt + 1,
        lastAcknowledgeAt: DateTime.now(),
      );
      _words[idx] = updatedWord;
      WORDS[WORDS.indexWhere((element) => element.id == id)] = updatedWord;
      _words.removeAt(idx);
      _emit();
    }, 'acknowledgeWord: id: $id');
  }

  Future<void> toggleIsKnown(String id) async {
    return tryCatch(() async {
      final idx = _words.indexWhere((x) => x.id == id);
      if (idx == -1) {
        throw NotFoundException('word ($id) does not exists anymore');
      }

      final wasKnown = _words[idx].known;

      final updatedWord = _words[idx].copyWith(
        known: !wasKnown,
        acknowledgesCnt: _words[idx].acknowledgesCnt + (wasKnown ? 0 : 1),
        lastAcknowledgeAt:
            wasKnown ? _words[idx].lastAcknowledgeAt : DateTime.now(),
      );

      WORDS[WORDS.indexWhere((element) => element.id == id)] = updatedWord;
      _words[idx] = updatedWord;
      _emit();
    }, 'toggleIsKnown: id: $id');
  }

  Future<void> deleteWord(String id) async {
    return tryCatch(() async {
      WORDS.removeWhere((x) => x.id == id);
      _words.removeWhere((x) => x.id == id);
      _emit();
    }, 'deleteWord: id: $id');
  }

  Future<String> updateWord(
      {required String id, String? word, List<String>? translations}) async {
    return tryCatch(() async {
      final idx = _words.indexWhere((x) => x.id == id);
      if (idx == -1) {
        if (word != null && translations != null) {
          return addWord(word, translations);
        }
        throw NotFoundException('word ($id) does not exists anymore');
      }

      final updatedWord = _words[idx].copyWith(
        word: word,
        translations: translations,
      );

      WORDS[WORDS.indexWhere((element) => element.id == id)] = updatedWord;
      _words[idx] = updatedWord;
      _emit();
      return updatedWord.id;
    }, 'updateWord: id: $id');
  }
}
