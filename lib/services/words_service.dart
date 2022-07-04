import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import '../dummy-data/lang-words-dummy-data.dart';
import '../models/word.dart';
import 'exception.dart';

typedef WordsEvent = List<Word>;

class WordsService {
  static final WordsService _instance = WordsService._internal();
  final List<Word> _words = [];
  final _streamController = StreamController<WordsEvent>();
  late final Stream<WordsEvent> _stream =
      _streamController.stream.asBroadcastStream();
  var i = 0;
  Stream<WordsEvent> get stream {
    log('‼‼‼‼ getting stream');
    _emit();
    return _stream;
  }

  factory WordsService() {
    return _instance;
  }

  // named constructor
  WordsService._internal() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      _words.addAll(await _fetchWords());
      log('pushing words ${_words.length}');
      _emit();
    });
  }

  void _emit() => _streamController.add(_words);

  Future<List<Word>> _fetchWords() async {
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
    return WORDS.any((element) => element.word.toLowerCase() == wordLowercased);
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
      // patch firebase
      WORDS[WORDS.indexWhere((element) => element.id == id)] = updatedWord;
      // remove from visible elements
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
      _words.removeWhere((x) => x.id == id);
      _emit();
    }, 'deleteWord: id: $id');
  }

  Future<void> updateWord(
      {required String id, String? word, List<String>? translations}) async {
    return tryCatch(() async {
      final idx = _words.indexWhere((x) => x.id == id);
      if (idx == -1) {
        throw NotFoundException('word ($id) does not exists anymore');
      }

      final updatedWord = _words[idx].copyWith(
        word: word,
        translations: translations,
      );

      WORDS[WORDS.indexWhere((element) => element.id == id)] = updatedWord;
      _words[idx] = updatedWord;
      _emit();
    }, 'updateWord: id: $id');
  }
}
