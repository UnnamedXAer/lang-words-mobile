import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

import '../models/word.dart';
import 'auth_service.dart';
import 'data_exception.dart';
import 'exception.dart';

typedef WordsEvent = List<Word>;

const Duration timeoutDuration = Duration(seconds: 10);

class WordsService {
  static final WordsService _instance = WordsService._internal();
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  final List<Word> _words = [];
  DateTime? _wordsFetchTime;
  int _initWordsState = 0;
  int _initKnownWordsLength = 0;
  final _streamController = StreamController<WordsEvent>.broadcast();

  Stream<WordsEvent> get stream => _streamController.stream;
  int get initWordsLength => _initWordsState;
  int get initKnownWordsLength => _initKnownWordsLength;
  bool get _canSkipFetchingWords {
    return _wordsFetchTime != null &&
        _wordsFetchTime!.isAfter(
          DateTime.now().subtract(
            const Duration(hours: 1),
          ),
        );
  }

  String _getWordsRefPath(String uid) {
    return '$uid/words';
  }

  final bool _useRESTApi =
      !(Platform.isIOS || Platform.isAndroid || Platform.isMacOS);

  factory WordsService() {
    return _instance;
  }

  WordsService._internal();

  void _emit() => _streamController.add(_words);

  void clear() {
    _words.clear();
    _initKnownWordsLength = 0;
    _initKnownWordsLength = 0;
    _wordsFetchTime = null;
  }

  Future<void> fetchWords(String? uid, [bool canSkipRefetching = false]) async {
    if (canSkipRefetching && _canSkipFetchingWords) {
      if (kDebugMode) {
        print('💤 words fetching skipped');
      }
      _emit();
      return;
    }

    var words = <Word>[];
    Object? data;

    try {
      await tryCatch(uid, (uid) async {
        if (_useRESTApi) {
          data = await _fetchWordsByREST(uid);
        } else {
          final ref = _database.ref(_getWordsRefPath(uid));

          final wordsSnapshot =
              await Future.sync(ref.get).timeout(timeoutDuration);

          data = wordsSnapshot.value;
        }
      }, 'fetch words');
    } on AppException catch (ex) {
      _streamController.addError(ex);
      return;
    }

    if (data != null) {
      (data as Map<dynamic, dynamic>).forEach(
        (key, value) {
          words.add(
            Word.fromFirebase(
              key,
              value,
            ),
          );
        },
      );

      words.sort(
        (a, b) =>
            (a.lastAcknowledgeAt ?? a.createAt).microsecondsSinceEpoch -
            (b.lastAcknowledgeAt ?? b.createAt).microsecondsSinceEpoch,
      );
    }

    _words.clear();
    _words.addAll(words);
    _initWordsState = _words.where((element) => !element.known).length;
    _initKnownWordsLength = _words.length - _initKnownWordsLength;
    _wordsFetchTime = DateTime.now();
    _emit();
  }

  Future<Object?> _fetchWordsByREST(String uid) async {
    final token = await AuthService().getIdToken();

    final uri = Uri.parse(
        '${_database.app.options.databaseURL}/${_getWordsRefPath(uid)}.json?auth=$token');
    final response = await http.get(
      uri,
    );

    checkResponseForErrorPhraseAndCode(response);

    final data = jsonDecode(response.body);

    return data;
  }

  Future<String> addWord(
      String? uid, String word, List<String> translations) async {
    final newWord = Word(
      id: DateTime.now().toString(),
      word: word,
      translations: [...translations],
      createAt: DateTime.now(),
      lastAcknowledgeAt: null,
      acknowledgesCnt: 0,
      known: false,
    );

    final Map<String, dynamic> data = newWord.toJson();

    // TODO: validation on the firebase side with function before save
    final newId = await tryCatch<String>(
      uid,
      (uid) async {
        final ref = _database.ref(_getWordsRefPath(uid)).push();
        final newId = ref.key;
        if (newId == null) {
          throw GenericException('fail to generate id for the new word');
        }
        if (_useRESTApi) {
          await _upsertWordViaREST(ref.path, data);
        } else {
          await Future.sync(() => ref.set(data)).timeout(timeoutDuration);
        }

        return newId;
      },
      'add word',
    );

    final savedWord = newWord.copyWith(id: newId);

    _words.insert(0, savedWord);
    _initWordsState++;
    _emit();

    return savedWord.id;
  }

  /// Checks whether given string - `word` already exists in current user's words
  ///
  /// If `id` is not null it will ignore record with given id.
  Future<bool> checkIfWordExists(String word, {String? id}) async {
    final wordLowercased = word.toLowerCase();

    return _words
        .any((x) => x.word.toLowerCase() == wordLowercased && x.id != id);
  }

  Future<void> acknowledgeWord(String? uid, String id) async {
    return tryCatch(uid, (uid) async {
      final idx = _words.indexWhere((x) => x.id == id);
      if (idx == -1) {
        throw NotFoundException('word ($id) does not exists anymore');
      }

      final updatedWord = _words[idx].copyWith(
        acknowledgesCnt: _words[idx].acknowledgesCnt + 1,
        lastAcknowledgeAt: DateTime.now(),
      );

      final ref = _database.ref('${_getWordsRefPath(uid)}/$id');

      final Map<String, Object?> data = {
        'acknowledgesCnt': {
          ".sv": {"increment": 1}
        },
        'lastAcknowledgeAt': {".sv": "timestamp"},
      };

      if (_useRESTApi) {
        await _upsertWordViaREST(ref.path, data);
      } else {
        await Future.sync(() => ref.update(data)).timeout(timeoutDuration);
      }

      _words[idx] = updatedWord;
      _words.removeAt(idx);
      _emit();
    }, 'acknowledgeWord: id: $id');
  }

  Future<void> toggleIsKnown(String? uid, String id) async {
    return tryCatch(uid, (uid) async {
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

      final Map<String, Object?> data = {
        "known": updatedWord.known,
        'acknowledgesCnt': {
          ".sv": {"increment": wasKnown ? 0 : 1},
        },
      };

      if (!wasKnown) {
        data['lastAcknowledgeAt'] = {".sv": "timestamp"};
      }

      final ref = _database.ref('${_getWordsRefPath(uid)}/$id');
      if (_useRESTApi) {
        await _upsertWordViaREST(ref.path, data);
      } else {
        await Future.sync(() => ref.update(data)).timeout(timeoutDuration);
      }

      _words[idx] = updatedWord;
      _emit();
    }, 'toggleIsKnown: id: $id');
  }

  Future<void> deleteWord(String? uid, String id) async {
    return tryCatch(uid, (uid) async {
      final ref = _database.ref('${_getWordsRefPath(uid)}/$id');

      if (_useRESTApi) {
        await _removeWordViaREST(ref.path);
      } else {
        await Future.sync(ref.remove).timeout(timeoutDuration);
      }

      final index = _words.indexWhere((x) => x.id == id);
      if (index != -1) {
        final removedWord = _words[index];
        if (removedWord.known) {
          _initKnownWordsLength--;
        } else {
          _initWordsState--;
        }

        _words.removeAt(index);
      }

      _emit();
    }, 'deleteWord: id: $id');
  }

  Future<String> updateWord({
    required String? uid,
    required String id,
    String? word,
    List<String>? translations,
  }) async {
    return tryCatch(uid, (uid) async {
      final idx = _words.indexWhere((x) => x.id == id);
      if (idx == -1) {
        if (word != null && translations != null) {
          return addWord(uid, word, translations);
        }
        throw NotFoundException('word ($id) does not exists anymore');
      }

      final Map<String, Object?> data = {
        'word': word,
        'translations': translations,
      };

      final ref = _database.ref('${_getWordsRefPath(uid)}/$id');
      if (_useRESTApi) {
        await _upsertWordViaREST(ref.path, data);
      } else {
        await Future.sync(() => ref.update(data)).timeout(timeoutDuration);
      }
      final updatedWord = _words[idx].copyWith(
        word: word,
        translations: translations,
      );

      _words[idx] = updatedWord;
      _emit();
      return updatedWord.id;
    }, 'updateWord: id: $id');
  }

  Future<void> _upsertWordViaREST(
    String path,
    Map<String, dynamic> data,
  ) async {
    final token = await AuthService().getIdToken();

    final uri = Uri.parse(
      '${_database.app.options.databaseURL}/$path.json?auth=$token',
    );

    final response = await http.patch(
      uri,
      body: jsonEncode(data),
    );

    checkResponseForErrorPhraseAndCode(response);
  }

  Future<void> _removeWordViaREST(String path) async {
    final token = await AuthService().getIdToken();

    final uri = Uri.parse(
      '${_database.app.options.databaseURL}/$path.json?auth=$token',
    );

    final response = await http.delete(uri);

    checkResponseForErrorPhraseAndCode(response);
  }
}

void checkResponseForErrorPhraseAndCode(http.Response response) {
  if (response.reasonPhrase != 'OK') {
    String msg = response.reasonPhrase ?? '';

    if (response.body.isNotEmpty) {
      try {
        final responseBody = jsonDecode(response.body);
        if (responseBody is Map && responseBody.containsKey('error')) {
          if (msg.isNotEmpty) {
            msg += ' / ';
          }
          msg += responseBody['error'];
        }
      } catch (_) {
        // nothing to do here, we stick to the reason phrase.
      }
    }
    throw Exception(msg);
  } else if (response.statusCode != 200) {
    throw Exception(
      'status code: ${response.statusCode}',
    );
  }
}
