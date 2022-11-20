import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:lang_words/models/word.dart';
import 'package:lang_words/services/object_box_service.dart';

import 'auth_service.dart';
import 'data_exception.dart';
import 'exception.dart';

typedef WordsEvent = List<Word>;

const Duration timeoutDuration = Duration(seconds: kDebugMode ? 5 : 20);

class WordsService {
  static final WordsService _instance = WordsService._internal();
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  final List<Word> _words = [];
  DateTime? _wordsRefreshTime;
  int _initWordsState = 0;
  int _initKnownWordsLength = 0;
  final _streamController = StreamController<WordsEvent>.broadcast();

  Stream<WordsEvent> get stream => _streamController.stream;
  int get initWordsLength => _initWordsState;
  int get initKnownWordsLength => _initKnownWordsLength;
  bool get _canSkipFetchingWords {
    return _wordsRefreshTime != null &&
        _wordsRefreshTime!.isAfter(
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

  Future<void> purgeOutstandingFirebaseWrites() async {
    try {
      await _database.purgeOutstandingWrites();
      if (kDebugMode) {
        print('ℹ️ purgeOutstandingFirebaseWrites done');
      }
    } catch (err) {
      log('⚠️ purgeOutstandingFirebaseWrites: err: $err');
    }
  }

  final bool _useRESTApi =
      !(Platform.isIOS || Platform.isAndroid || Platform.isMacOS);

  factory WordsService() {
    return _instance;
  }

  WordsService._internal() {
    _database.setPersistenceEnabled(false);
  }

  void _emit() => _streamController.add(_words);

  Word? firstWhere(bool Function(Word w) test) {
    return _words.firstWhere(test);
  }

  void clear() {
    _words.clear();
    _initKnownWordsLength = 0;
    _initKnownWordsLength = 0;
    _wordsRefreshTime = null;
  }

  Future<Word?> firebaseFetchWord(String? uid, String wordFirebaseId) async {
    _checkUid(uid, 'firebaseFetchWord');
    final path = '${_getWordsRefPath(uid!)}/$wordFirebaseId';
    final ref = _database.ref(path);

    final wordSnapshot = await ref.get().timeout(timeoutDuration);
    final data = wordSnapshot.value;

    if (data == null) {
      return null;
    }

    final word =
        Word.fromFirebase(wordFirebaseId, uid, data as Map<dynamic, dynamic>);

    return word;
  }

  Future<void> refreshWordsList(String? uid,
      [bool canSkipRefetching = false]) async {
    if (canSkipRefetching && _canSkipFetchingWords) {
      if (kDebugMode) {
        print('💤 words refreshing skipped');
      }
      _emit();
      return;
    }

    var words = <Word>[];
    final box = ObjectBoxService();
    words = box.getAllWords(uid!);

    words.sort(
      (a, b) =>
          (a.lastAcknowledgeAt ?? a.createAt).microsecondsSinceEpoch -
          (b.lastAcknowledgeAt ?? b.createAt).microsecondsSinceEpoch,
    );

    log('_words #: ${words.length}');

    _words.clear();
    _words.addAll(words);
    _initWordsState = _words.where((element) => !element.known).length;
    _initKnownWordsLength = _words.length - _initKnownWordsLength;
    _wordsRefreshTime = DateTime.now();
    _emit();
  }

  Future<List<Word>> firebaseFetchWords(String? uid) async {
    Object? data;
    var words = <Word>[];
    await firebaseTryCatch(uid, (uid) async {
      if (_useRESTApi) {
        data = await _fetchWordsByREST(uid);
      } else {
        final ref = _database.ref(_getWordsRefPath(uid));

        final wordsSnapshot = await ref.get().timeout(timeoutDuration);

        data = wordsSnapshot.value;
      }
    }, 'fetch words');

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

    return words;
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
      posted: false,
    );

    final boxService = ObjectBoxService();
    final savedWordId = await boxService.saveWord(uid, newWord);

    _words.insert(0, newWord);
    _initWordsState++;
    _emit();

    firebaseAddWord(ref, newWord).then((success) {
      if (success) {
        boxService.removeEditedWords(savedWordId);

        final idx = _words.indexWhere(
          (element) => element.id == savedWordId,
        );
        if (idx == -1) {
          return;
        }

        _words[idx].posted = true;
        boxService.setWordPosted(_words[idx]);
      }
    });

    return newWord.firebaseId;
  }

  Future<bool> firebaseAddWord(DatabaseReference ref, Word word) {
    return firebaseTryCatch<bool>(word.firebaseUserId, (uid) async {
      final Map<String, dynamic> data = word.toJson();

      if (_useRESTApi) {
        await _upsertWordViaREST(ref.path, data);
      } else {
        await ref.set(data).timeout(timeoutDuration);
      }

      return true;
    }, 'firebaseAddWord')
        .catchError((err) {
      debugPrint('🖨️ firebaseAddWord: $err');
      return false;
    });
  }

  Future<bool> checkIfWordExists(
    String word, {
    String? firebaseIdToIgnore,
  }) async {
    final box = ObjectBoxService();
    final exists =
        box.checkIfWordExists(word, firebaseIdToIgnore: firebaseIdToIgnore);

    if (kDebugMode) {
      print('word "$word" ${exists ? 'already' : 'not'} exists');
    }

    return exists;
  }

  Future<void> acknowledgeWord(
    String? uid,
    String firebaseId,
  ) async {
    _checkUid(uid, 'acknowledgeWord');

    final idx = _words.indexWhere((x) => x.firebaseId == firebaseId);
    bool posted = false;
    if (idx != -1) {
      posted = _words[idx].posted;
      _words.removeAt(idx);
      _emit();
    }

    final DateTime now = DateTime.now();

    final localWords = ObjectBoxService();
    final acknowledgedWordId = await localWords.acknowledgeWord(
      uid!,
      firebaseId,
      now,
    );

    if (!posted) {
      return;
    }

    firebaseAcknowledgeWord(uid, firebaseId, 1, now).then((success) {
      if (success) {
        localWords.decreaseAcknowledgedWordCount(acknowledgedWordId);
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
        'lastAcknowledgeAt': lastAcknowledgeAt.millisecondsSinceEpoch,
      };

      if (_useRESTApi) {
        await _upsertWordViaREST(ref.path, data);
      } else {
        await ref.update(data).timeout(timeoutDuration);
      }

      return true;
    }, 'firebaseAcknowledgeWord: id: $firebaseId')
        .catchError((err) {
      debugPrint('🖨️ firebaseAcknowledgeWord: $err');
      return false;
    });
  }

  Future<void> toggleIsKnown(String? uid, String firebaseId) async {
    _checkUid(uid, 'toggleIsKnown');
    final idx = _words.indexWhere((x) => x.firebaseId == firebaseId);
    if (idx == -1) {
      throw NotFoundException(
        'Sorry, could not toggle this word.',
        'word ($firebaseId) does not exists in the _words list anymore.',
      );
    }

    final oldWord = _words[idx];

    final wasKnown = oldWord.known;

    final updatedWord = oldWord.copyWith(
      known: !wasKnown,
      acknowledgesCnt: oldWord.acknowledgesCnt + (wasKnown ? 0 : 1),
      lastAcknowledgeAt: wasKnown && oldWord.lastAcknowledgeAt != null
          // workaround: this one millisecond is for merging words so it appear newer
          // when it was unmarked from known words
          ? oldWord.lastAcknowledgeAt!.add(const Duration(milliseconds: 1))
          : DateTime.now(),
    );

    final localWords = ObjectBoxService();
    final toggledWordId = await localWords.toggleWordIsKnown(uid!, updatedWord);
    int? acknowledgedWord;
    if (updatedWord.known) {
      acknowledgedWord = await localWords.increaseWordAcknowledges(
        uid,
        updatedWord.id,
        firebaseId,
        updatedWord.lastAcknowledgeAt!,
      );
    }

    assert(oldWord.known != updatedWord.known);

    _words[idx] = updatedWord;
    _emit();

    if (!updatedWord.posted) {
      return;
    }

    firebaseToggleIsKnown(uid, updatedWord).then((success) {
      if (success) {
        localWords.removeToggledIsKnownWord(toggledWordId);
        if (acknowledgedWord != null) {
          localWords.removeAcknowledgedWord(acknowledgedWord);
        }
      }
    });
  }

  Future<bool> firebaseToggleIsKnown(String uid, Word updatedWord) {
    return firebaseTryCatch<bool>(uid, (uid) async {
      final Map<String, Object?> data = {
        "known": updatedWord.known,
        'acknowledgesCnt': {
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
        await ref.update(data).timeout(timeoutDuration);
      }

      return true;
    }, 'firebaseToggleIsKnown: id: ${updatedWord.firebaseId}')
        .catchError((err) {
      if (kDebugMode) {
        print('firebaseToggleIsKnown: $err');
      }
      return false;
    });
  }

  Future<void> deleteWord(String? uid, int wordId, String firebaseId) async {
    _checkUid(uid, 'deleteWord');

    final boxService = ObjectBoxService();
    final deletedWordId = await boxService.deleteWord(uid!, wordId, firebaseId);

    final index = _words.indexWhere((x) => x.id == wordId);
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

    firebaseDeleteWord(uid, firebaseId).then((success) {
      if (success) {
        boxService.removeDeletedWords(deletedWordId);
      }
    });
  }

  Future<bool> firebaseDeleteWord(String? uid, String firebaseId) async {
    return firebaseTryCatch(uid, (uid) async {
      final ref = _database.ref('${_getWordsRefPath(uid)}/$firebaseId');

      if (_useRESTApi) {
        await _removeWordViaREST(ref.path);
      } else {
        await ref.remove().timeout(timeoutDuration);
      }

      return true;
    }, 'deleteWord: id: $firebaseId')
        .catchError((err) {
      if (kDebugMode) {
        print('delete word: $err');
      }
      return false;
    });
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
    await boxService.saveWord(uid!, updatedWord);

    _words[idx] = updatedWord;
    _emit();

    if (!updatedWord.posted) {
      return updatedWord.firebaseId;
    }

    firebaseUpdateWord(uid, updatedWord).then((success) {
      if (success) {
        boxService.removeEditedWords(updatedWord.id);
      }
    });

    return updatedWord.firebaseId;
  }

  Future<bool> firebaseUpdateWord(String uid, Word updatedWord) {
    return firebaseTryCatch<bool>(uid, (uid) async {
      final Map<String, Object?> data = {
        'word': updatedWord.word,
        'translations': updatedWord.translations,
      };

      final ref =
          _database.ref('${_getWordsRefPath(uid)}/${updatedWord.firebaseId}');
      if (_useRESTApi) {
        await _upsertWordViaREST(ref.path, data);
      } else {
        await ref.update(data).timeout(timeoutDuration);
      }

      return true;
    }, 'updateWord: id: ${updatedWord.firebaseId}')
        .catchError((err) {
      debugPrint('🖨️ firebaseUpdateWord: $err');
      return false;
    });
  }

  Future<bool> firebaseUpsertWord(String uid, Word word) {
    return firebaseTryCatch<bool>(uid, (uid) async {
      final data = word.toJson();

      final ref = _database.ref('${_getWordsRefPath(uid)}/${word.firebaseId}');
      if (_useRESTApi) {
        await _upsertWordViaREST(ref.path, data);
      } else {
        await ref.update(data).timeout(timeoutDuration);
      }

      return true;
    }, 'UpsertWord: id: ${word.firebaseId}')
        .catchError((err) {
      if (kDebugMode) {
        print('upsert word: $err');
      }
      return false;
    });
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
