import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

import '../firebase_options.dart';
import '../models/word.dart';
import 'data_exception.dart';
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

  Future<void> fetchWords(String? uid) async {
    if (uid == null) {
      return _streamController.addError(
        UnauthorizeException('fetchWords: uid is null'),
      );
    }

    var words = <Word>[];

    late Object? data;
    if (_useRESTApi) {
      data = await _fetchWordsByREST(uid!);
    } else {
      final ref = _database.ref(_getWordsRefPath(uid!));
      final wordsSnapshot = await ref.get();

      data = wordsSnapshot.value;
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
    _emit();
  }

  Future<Object?> _fetchWordsByREST(String uid) async {
    final uri = Uri.parse(
        '${DefaultFirebaseOptions.web.databaseURL}/${_getWordsRefPath(uid)}.json');
    final response = await http.get(
      uri,
    );

    if (response.reasonPhrase != 'OK') {
      throw Exception(response.reasonPhrase);
    } else if (response.statusCode != 200) {
      throw GenericException();
    }

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
          throw GenericException('could not get new Id for the word');
        }
        if (_useRESTApi) {
          await _upsertWordViaREST(ref.path, data);
        }
        ref.set(data);

        return newId;
      },
      'add word',
    );

    final savedWord = newWord.copyWith(id: newId);

    _words.insert(0, savedWord);
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
        ref.update(data);
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
        await ref.update(data);
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
        await ref.remove();
      }

      _words.removeWhere((x) => x.id == id);
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
        await ref.update(data);
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
    final uri = Uri.parse(
      '${DefaultFirebaseOptions.web.databaseURL}/$path.json',
    );

    final response = await http.patch(
      uri,
      body: jsonEncode(data),
    );

    if (response.reasonPhrase != 'OK') {
      String? msg = response.reasonPhrase;

      if (response.body.isNotEmpty) {
        try {
          final responseBody = jsonDecode(response.body);
          if (responseBody is Map && responseBody.containsKey('error')) {
            msg = responseBody['error'];
          }
        } catch (_) {
          // nothing to do here, we stick to the reason phrase.
        }
      }
      throw Exception(msg);
    } else if (response.statusCode != 200) {
      throw GenericException();
    }
  }

  Future<void> _removeWordViaREST(String path) async {
    final uri = Uri.parse(
      '${DefaultFirebaseOptions.web.databaseURL}/$path.json',
    );

    final response = await http.delete(
      uri,
    );

    if (response.reasonPhrase != 'OK') {
      String? msg = response.reasonPhrase;

      if (response.body.isNotEmpty) {
        try {
          final responseBody = jsonDecode(response.body);
          if (responseBody is Map && responseBody.containsKey('error')) {
            msg = responseBody['error'];
          }
        } catch (_) {
          // nothing to do here, we stick to the reason phrase.
        }
      }
      throw Exception(msg);
    } else if (response.statusCode != 200) {
      throw GenericException();
    }
  }
}
