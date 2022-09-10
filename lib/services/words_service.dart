import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:lang_words/models/word.dart';
import 'package:lang_words/services/words_local_service.dart';

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

  void _checkUid(String? uid, String errorLabel) {
    if (uid == null) {
      throw UnauthorizeException('$errorLabel: uid is null');
    }
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

  Word? firstWhere(bool Function(Word w) test) {
    return _words.firstWhere(test);
  }

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
      await firebaseTryCatch(uid, (uid) async {
        final box = ObjectBoxService();

        // words = box.getAllWords(uid);
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
              uid!,
              value,
            ),
          );
        },
      );
    }
    words.sort(
      (a, b) =>
          (a.lastAcknowledgeAt ?? a.createAt).microsecondsSinceEpoch -
          (b.lastAcknowledgeAt ?? b.createAt).microsecondsSinceEpoch,
    );

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
    _checkUid(uid, 'addWord');

    late final Word newWord;
    final ref = _database.ref(_getWordsRefPath(uid!)).push();
    final firebaseId = ref.key;
    if (firebaseId == null) {
      throw GenericException('fail to generate id for the new word');
    }

    newWord = Word(
      id: 0,
      firebaseId: firebaseId,
      firebaseUserId: uid,
      word: word,
      translations: [...translations],
      createAt: DateTime.now(),
      lastAcknowledgeAt: null,
      acknowledgesCnt: 0,
      known: false,
    );

    final boxService = ObjectBoxService();
    await boxService.saveWord(newWord, uid);

    _words.insert(0, newWord);
    _initWordsState++;
    _emit();

    firebaseAddWord(ref, newWord).then((success) {
      if (success) {
        boxService.removeEditedWords(firebaseId);
      }
    });

    return newWord.firebaseId;
  }

  Future<bool> firebaseAddWord(DatabaseReference ref, Word word) async {
    // TODO: validation on the firebase side with function before save

    return firebaseTryCatch<bool>(
      word.firebaseUserId,
      (uid) async {
        final Map<String, dynamic> data = word.toJson();

        if (_useRESTApi) {
          await _upsertWordViaREST(ref.path, data);
        } else {
          await Future.sync(() => ref.set(data)).timeout(timeoutDuration);
        }

        return true;
      },
      'firebaseAddWord',
    ).catchError((err) {
      if (kDebugMode) {
        print('firebaseAddWord: $err');
      }
      return false;
    });
  }

  Future<bool> checkIfWordExists(
    String word, {
    String? firebaseIdToIgnore,
  }) async {
    final wordLowercased = word.toLowerCase();

    // TODO: check against objectbox

    return _words.any((x) =>
        x.word.toLowerCase() == wordLowercased &&
        x.firebaseId != firebaseIdToIgnore);
  }

  Future<void> acknowledgeWord(
    String? uid,
    String firebaseId,
  ) async {
    _checkUid(uid, 'acknowledgeWord');

    final idx = _words.indexWhere((x) => x.firebaseId == firebaseId);
    if (idx == -1) {
      // TODO: check: that id should not be shown to the user.
      throw NotFoundException('word ($firebaseId) does not exists anymore');
    }

    _words.removeAt(idx);
    _emit();

    final DateTime now = DateTime.now();

    final localWords = ObjectBoxService();
    await localWords.acknowledgeWord(uid!, firebaseId, now);

    firebaseAcknowledgeWord(uid, firebaseId, 1, now).then((success) {
      if (success) {
        localWords.removeAcknowledgeWord(firebaseId);
      }
    });
  }

  Future<bool> firebaseAcknowledgeWord(String uid, String firebaseId,
      int acknowledgeCount, DateTime lastAcknowledgeAt) async {
    return firebaseTryCatch(uid, (uid) async {
      final ref = _database.ref('${_getWordsRefPath(uid)}/$firebaseId');

      final Map<String, Object?> data = {
        'acknowledgesCnt': {
          ".sv": {"increment": acknowledgeCount}
        },
        'lastAcknowledgeAt': lastAcknowledgeAt
            .millisecondsSinceEpoch, // ?? {".sv": "timestamp"},
      };

      if (_useRESTApi) {
        await _upsertWordViaREST(ref.path, data);
      } else {
        await Future.sync(() => ref.update(data)).timeout(timeoutDuration);
      }

      return true;
    }, 'firebaseAcknowledgeWord: id: $firebaseId')
        .catchError((err) {
      if (kDebugMode) {
        print('firebaseAcknowledgeWord: $err');
      }
      return false;
    });
  }

  Future<void> toggleIsKnown(String? uid, String firebaseId) async {
    _checkUid(uid, 'acknowledgeWord');
    final idx = _words.indexWhere((x) => x.firebaseId == firebaseId);
    if (idx == -1) {
      throw NotFoundException('word ($firebaseId) does not exists anymore');
    }
    final wasKnown = _words[idx].known;

    final updatedWord = _words[idx].copyWith(
      known: !wasKnown,
      acknowledgesCnt: _words[idx].acknowledgesCnt + (wasKnown ? 0 : 1),
      lastAcknowledgeAt: wasKnown && _words[idx].lastAcknowledgeAt != null
          ? _words[idx].lastAcknowledgeAt!
          : DateTime.now(),
    );

    final localWords = ObjectBoxService();
    final toggledWordBoxId =
        await localWords.toggleWordIsKnown(uid!, updatedWord);

    _words[idx] = updatedWord;
    _emit();

    firebaseToggleIsKnown(uid, updatedWord).then((success) {
      if (success) {
        localWords.removeToggledIsKnownWord(toggledWordBoxId);
      }
    });
  }

  Future<bool> firebaseToggleIsKnown(String uid, Word updatedWord) {
    return firebaseTryCatch<bool>(uid, (uid) async {
      final Map<String, Object?> data = {
        "known": updatedWord.known,
        'acknowledgesCnt': {
          // ".sv": {"increment": wasKnown ? 0 : 1},
          ".sv": {"increment": updatedWord.known ? 1 : 0},
        },
        'lastAcknowledgeAt':
            updatedWord.lastAcknowledgeAt?.millisecondsSinceEpoch
      };

      final ref =
          _database.ref('${_getWordsRefPath(uid)}/${updatedWord.firebaseId}');
      if (_useRESTApi) {
        await _upsertWordViaREST(ref.path, data);
      } else {
        await Future.sync(() => ref.update(data)).timeout(timeoutDuration);
      }

      return true;
    }, 'firebaseAcknowledgeWord: id: ${updatedWord.firebaseId}')
        .catchError((err) {
      if (kDebugMode) {
        print('firebaseAcknowledgeWord: $err');
      }
      return false;
    });
  }

  Future<void> deleteWord(String? uid, String firebaseId) async {
    return firebaseTryCatch(uid, (uid) async {
      final ref = _database.ref('${_getWordsRefPath(uid)}/$firebaseId');

      if (_useRESTApi) {
        await _removeWordViaREST(ref.path);
      } else {
        await Future.sync(ref.remove).timeout(timeoutDuration);
      }

      final index = _words.indexWhere((x) => x.firebaseId == firebaseId);
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
    }, 'deleteWord: id: $firebaseId');
  }

  Future<String> updateWord({
    required String? uid,
    required String firebaseId,
    String? word,
    List<String>? translations,
  }) async {
    _checkUid(uid, 'addWord');
    final idx = _words.indexWhere((x) => x.firebaseId == firebaseId);
    if (idx == -1) {
      if (word != null && translations != null) {
        return addWord(uid, word, translations);
      }
      throw NotFoundException('word ($firebaseId) does not exists anymore');
    }

    final updatedWord = _words[idx].copyWith(
      word: word,
      translations: translations,
    );

    final boxService = ObjectBoxService();
    await boxService.saveWord(updatedWord, uid!);

    _words[idx] = updatedWord;
    _emit();

    firebaseTryCatch<bool>(uid, (uid) async {
      final Map<String, Object?> data = {
        'word': word,
        'translations': translations,
      };

      final ref = _database.ref('${_getWordsRefPath(uid)}/$firebaseId');
      if (_useRESTApi) {
        await _upsertWordViaREST(ref.path, data);
      } else {
        await Future.sync(() => ref.update(data)).timeout(timeoutDuration);
      }

      return boxService.removeEditedWords(firebaseId);
    }, 'updateWord: id: $firebaseId')
        .catchError((err) {
      if (kDebugMode) {
        print('update word: $err');
      }
      return false;
    });

    return updatedWord.firebaseId;
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
