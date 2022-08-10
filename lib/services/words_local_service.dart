import 'dart:developer';

import 'package:lang_words/models/word.dart';
import 'package:lang_words/objectbox.g.dart';

class ObjectBoxService {
  static final ObjectBoxService _instance = ObjectBoxService._internal();
  late final Store _store;
  late final Box<Word> _wordBox;

  ObjectBoxService._internal();

  static Future initialize() async {
    _instance._store = await openStore();
    _instance._wordBox = _instance._store.box<Word>();
    return _instance;
  }

  factory ObjectBoxService() {
    return _instance;
  }

  //
  Future saveWord(Word word, String uid) async {
    final id = _wordBox.put(word);
    log('id: $id');
  }

  Future<List<Word>> getWords(String uid) async {
    final words = _wordBox.getAll();

    return words;
  }
}
