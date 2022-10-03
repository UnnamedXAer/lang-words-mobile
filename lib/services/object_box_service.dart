import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:lang_words/helpers/word_helper.dart';
import 'package:lang_words/models/acknowledged_word.dart';
import 'package:lang_words/models/deleted_word.dart';
import 'package:lang_words/models/edited_word.dart';
import 'package:lang_words/models/toggled_is_known_word.dart';
import 'package:lang_words/models/word.dart';
import 'package:lang_words/objectbox.g.dart';
import 'package:lang_words/services/auth_service.dart';
import 'package:lang_words/services/data_exception.dart';
import 'package:lang_words/services/words_service.dart';

import '../models/words_sync_ingo.dart';

class ObjectBoxService {
  static final ObjectBoxService _instance = ObjectBoxService._internal();
  late final Store _store;
  late final Admin? _admin;
  late final Box<Word> _wordBox;
  late final Box<DeletedWord> _deletedWordBox;
  late final Box<AcknowledgeWord> _acknowledgedWordBox;
  late final Box<ToggledIsKnownWord> _toggledIsKnownWordBox;
  late final Box<EditedWord> _editedWordBox;

  ObjectBoxService._internal();

  static Future initialize() async {
    _instance._store = await openStore();
    _instance._wordBox = _instance._store.box<Word>();
    _instance._deletedWordBox = _instance._store.box<DeletedWord>();
    _instance._acknowledgedWordBox = _instance._store.box<AcknowledgeWord>();
    _instance._toggledIsKnownWordBox =
        _instance._store.box<ToggledIsKnownWord>();
    _instance._editedWordBox = _instance._store.box<EditedWord>();

    if (kDebugMode && Admin.isAvailable()) {
      // TODO: this may cause build problems for flavors but may not
      _instance._admin = Admin(_instance._store);
    }

    return _instance;
  }

  factory ObjectBoxService() {
    return _instance;
  }

  bool checkIfWordExists(String word, {String? firebaseIdToIgnore}) {
    late final Condition<Word> conditions;

    if (firebaseIdToIgnore == null) {
      conditions = Word_.word.equals(word, caseSensitive: false);
    } else {
      conditions = Word_.word
          .equals(word, caseSensitive: false)
          .and(Word_.firebaseId.notEquals(firebaseIdToIgnore));
    }

    final query = _wordBox.query(conditions).build();

    final existingWordsCount = query.count();

    query.close();

    return existingWordsCount > 0;
  }

  Future<int> saveWord(String uid, Word word) async {
    final id = _wordBox.put(word);

    // final editedWordQuery = _editedWordBox
    //     .query(EditedWord_.firebaseId.equals(word.firebaseId))
    //     .build();

    // final ids = editedWordQuery.findIds();

    // editedWordQuery.close();

    final editedWord = EditedWord(
      id: id, //ids.isNotEmpty ? ids.first : 0,
      firebaseId: word.firebaseId,
      firebaseUserId: word.firebaseUserId,
      editedAt: DateTime.now(),
    );

    final editedWordId = await _editedWordBox.putAsync(editedWord);

    log('+++ saveWord: ${word.firebaseId}, $id');

    return editedWordId;
  }

  List<Word> getAllWords(String uid) {
    final query = _wordBox.query(Word_.firebaseUserId.equals(uid)).build();
    final words = query.find();
    query.close();
    return words;
  }

  Future<int> deleteWord(String uid, int wordId, String firebaseId) async {
    _removeWord(wordId);

    final deletedWordId = await _deletedWordBox.putAsync(
      DeletedWord(
        id: wordId,
        firebaseId: firebaseId,
        firebaseUserId: uid,
      ),
    );

    removeEditedWords(wordId);
    removeAcknowledgedWords(wordId);
    removeToggledIsKnownWords(wordId);

    log('+++ deleteWord: $firebaseId, $deletedWordId');

    return deletedWordId;
  }

  bool _removeWord(int id) {
    // final query = _wordBox.query(Word_.firebaseId.equals(firebaseId)).build();

    // final removed = query.remove() > 0;

    // query.close();

    final removed = _wordBox.remove(id);

    log('--- _removeWord: $id, $removed');

    return removed;
  }

  bool removeDeletedWords(int wordId) {
    // final query = _deletedWordBox
    //     .query(DeletedWord_.firebaseId.equals(firebaseId))
    //     .build();

    // final removed = query.remove() > 0;

    // query.close();

    final removed = _deletedWordBox.remove(wordId);

    log('--- removeDeletedWords: $wordId, $removed');
    return removed;
  }

  Future<int> acknowledgeWord(
      String uid, String firebaseId, DateTime acknowledgedAt) async {
    final wordQuery =
        _wordBox.query(Word_.firebaseId.equals(firebaseId)).build();

    final word = wordQuery.findFirst();
    wordQuery.close();

    // If the word exists locally we update.
    // TODO: We could pass the Word object to this function instead of the id and time
    // and insert that word if not exists yet.
    if (word == null) {
      throw NotFoundException(
        'Sorry, could not acknowledge this word.',
        'word: $firebaseId not found in the OB.',
      );
    }
    word.acknowledgesCnt++;
    word.lastAcknowledgeAt = acknowledgedAt;

    await _wordBox.putAsync(word, mode: PutMode.update);

    AcknowledgeWord? acknowledge = _acknowledgedWordBox.get(word.id);

    if (acknowledge != null) {
      acknowledge.count++;
      acknowledge.lastAcknowledgedAt = acknowledgedAt;
    } else {
      acknowledge = AcknowledgeWord(
        id: word.id,
        firebaseId: firebaseId,
        firebaseUserId: uid,
        count: 1,
        lastAcknowledgedAt: acknowledgedAt,
      );
    }

    await _acknowledgedWordBox.putAsync(acknowledge);

    log('+++ acknowledgeWord: $firebaseId, ${acknowledge.id}');

    return acknowledge.id;
  }

  Future<bool> decreaseAcknowledgedWordCount(int wordId) async {
    final word = _acknowledgedWordBox.get(wordId);

    if (word == null) {
      log('--- decreaseAcknowledgedWordCount: ack word with id: $wordId, does not exists.');
      return false;
    }

    if (word.count <= 1) {
      log('--- decreaseAcknowledgedWordCount: ${word.firebaseId}, count == ${word.count}, removing...');
      _acknowledgedWordBox.remove(wordId);
      log('--- decreaseAcknowledgedWordCount: ${word.firebaseId}, count == ${word.count}, removed');
      return true;
    }

    log('--- decreaseAcknowledgedWordCount: ${word.firebaseId}, decreasing...');

    word.count -= 1;
    await _acknowledgedWordBox.putAsync(word, mode: PutMode.update);

    log('--- decreaseAcknowledgedWordCount: ${word.firebaseId}, decreased');

    return true;
  }

  bool removeAcknowledgedWords(int wordId) {
    // final query = _acknowledgedWordBox
    //     .query(AcknowledgeWord_.firebaseId.equals(firebaseId))
    //     .build();

    // final removed = query.remove() > 0;

    // query.close();

    final removed = _acknowledgedWordBox.remove(wordId);

    log('--- removeAcknowledgeWord: $wordId, $removed');
    return removed;
  }

  Future<int> toggleWordIsKnown(String uid, Word word) async {
    if (word.id == 0) {
      await saveWord(uid, word);
    }

    final toggledId = await _toggledIsKnownWordBox.putAsync(
      ToggledIsKnownWord(
        id: word.id,
        firebaseId: word.firebaseId,
        firebaseUserId: uid,
        toggledAt: word.lastAcknowledgeAt!,
        isKnown: word.known,
      ),
    );

    _wordBox.putAsync(word, mode: PutMode.put);

    log('+++ toggleWordIsKnown: ${word.firebaseId}, $toggledId');

    return toggledId;
  }

  bool removeToggledIsKnownWord(int toggledWordId) {
    return _toggledIsKnownWordBox.remove(toggledWordId);
  }

  bool removeToggledIsKnownWords(int wordId) {
    // final query = _toggledIsKnownWordBox
    //     .query(ToggledIsKnownWord_.firebaseId.equals(firebaseId))
    //     .build();

    // final removed = query.remove() > 0;

    // query.close();

    final removed = _toggledIsKnownWordBox.remove(wordId);

    log('--- removeToggledIsKnownWords: $wordId, $removed');

    return removed;
  }

  bool removeEditedWords(int wordId) {
    // final query =
    //     _editedWordBox.query(EditedWord_.firebaseId.equals(firebaseId)).build();

    // final removed = query.remove() > 0;

    // query.close();

    final removed = _editedWordBox.remove(wordId);

    log('--- removeEditedWords: $wordId, $removed');

    return removed;
  }

  Future<void> syncWithRemote() async {
    log('🔃 --- synchronizing with remote...');

    final authService = AuthService();

    final uid = authService.appUser?.uid;

    if (uid == null) {
      return;
    }

    final syncBox = _store.box<WordsSyncInfo>();

    final syncQuery =
        syncBox.query(WordsSyncInfo_.firebaseUserId.equals(uid)).build();
    final syncInfo = syncQuery.findUnique();

    if (kDebugMode) {
      print('${syncInfo?.lastSyncAt}');
    }

    final ws = WordsService();
    _clearAll(uid);
    // _wordBox.getAll().forEach((element) async {
    //   await ws.addWord(uid, element.word, element.translations);
    // });
    // print('hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh');
    // final words = await ws.fetchWordsTmpForPopulatingOB(uid);
    await _syncDeletedWords(authService.appUser!.uid, ws);

    await _syncEditedWords(
      authService.appUser!.uid,
      ws,
    );

    return;
    log('🔃 --- synchronizing with remote - done');
    return;
    await _syncAcknowledgedWords(authService.appUser!.uid, ws);
    await _syncToggledIsKnownWords(authService.appUser!.uid, ws);
    // TODO: pull words new words from fireabse and add them to the OB
    // try to find duplicates and merge
  }

  Future<void> _syncDeletedWords(String uid, WordsService ws) async {
    final localDeletedWordsQuery =
        _deletedWordBox.query(DeletedWord_.firebaseUserId.equals(uid)).build();

    final localDeletedWords = localDeletedWordsQuery.find();
    localDeletedWordsQuery.close();

    for (var deletedWord in localDeletedWords) {
      // await ws.deleteWord(uid, deletedWord.id, deletedWord.firebaseId);
      await ws.firebaseDeleteWord(uid, deletedWord.firebaseId);
      _deletedWordBox.remove(deletedWord.id);
    }
  }

  Future<int> _syncEditedWords(String uid, WordsService ws) async {
    final localEditedWordsQuery =
        _editedWordBox.query(EditedWord_.firebaseUserId.equals(uid)).build();
    final localEditedWords = localEditedWordsQuery.find();
    localEditedWordsQuery.close();

    int fails = 0;

    for (var editedWord in localEditedWords) {
      final wordQuery = _wordBox
          .query(Word_.firebaseId.equals(editedWord.firebaseId))
          .build();

      Word? word = wordQuery.findFirst();
      wordQuery.close();

      if (word == null) {
        log('_syncEditedWords: edited word exists with firebaseId: ${editedWord.firebaseId}, but no matching word found in local words, skipped');
        continue;
      }

      final firebaseWord =
          await ws.firebaseFetchWord(uid, editedWord.firebaseId);

      if (firebaseWord != null) {
        final mergedWord = WordHelper.mergeWordsWithSameFirebaseId(
          firebaseWord,
          word,
          editedWord,
        );

        if (kDebugMode) {
          print('mergedWord: $mergedWord');
        }

        word = mergedWord;
      }

      final success = await ws.firebaseUpsertWord(uid, word);
      if (success) {
        _editedWordBox.remove(editedWord.id);
        continue;
      }
      fails++;
    }

    return fails;
  }

  Future<void> _syncAcknowledgedWords(String uid, WordsService ws) async {
    final localAcknowledgedWordsQuery = _acknowledgedWordBox
        .query(AcknowledgeWord_.firebaseUserId.equals(uid))
        .build();

    final localAcknowledgedWords = localAcknowledgedWordsQuery.find();
    localAcknowledgedWordsQuery.close();

    var i = 0;
    try {
      for (var acknowledgedWord in localAcknowledgedWords) {
        final success = await ws.firebaseAcknowledgeWord(
          uid,
          acknowledgedWord.firebaseId,
          acknowledgedWord.count,
          acknowledgedWord.lastAcknowledgedAt,
        );
        if (!success) {
          if (kDebugMode) {
            print(
                'synced acknowledges of ${acknowledgedWord.firebaseId} failed.');
          }
          continue;
        }
        _acknowledgedWordBox.remove(acknowledgedWord.id);
        if (kDebugMode) {
          print(
              'synced acknowledges of ${acknowledgedWord.firebaseId} cnt: ${acknowledgedWord.count}');
        }
      }
    } catch (err) {
      log('_syncAcknowledgedWords: $err');
    }

    // localAcknowledgedWordsQuery.remove();
  }

  Future<void> _syncToggledIsKnownWords(String uid, WordsService ws) async {
    final localToggledWordsQuery = _toggledIsKnownWordBox
        .query(ToggledIsKnownWord_.firebaseUserId.equals(uid))
        .build();

    final localToggledWords = localToggledWordsQuery.find();

    for (var toggledWord in localToggledWords) {
      final word =
          ws.firstWhere((word) => word.firebaseId == toggledWord.firebaseId);
    }
  }

  void _clearAll(String uid) {
    if (kReleaseMode) {
      return;
    }

    final wheres = [
      WordsSyncInfo_.firebaseUserId.equals(uid),
      Word_.firebaseUserId.equals(uid),
      EditedWord_.firebaseUserId.equals(uid),
      AcknowledgeWord_.firebaseUserId.equals(uid),
      ToggledIsKnownWord_.firebaseUserId.equals(uid),
      DeletedWord_.firebaseUserId.equals(uid),
    ];

    final boxes = [
      _store.box<WordsSyncInfo>(),
      _wordBox,
      _editedWordBox,
      _acknowledgedWordBox,
      _toggledIsKnownWordBox,
      _deletedWordBox,
    ];

    log('OB: clearAll ($uid): clearing...');

    _store.runInTransaction(TxMode.write, () {
      var i = 0;
      for (Box<Object> box in boxes) {
        var where = wheres[i++];
        final query = box.query(where).build();

        final cnt = query.remove();

        query.close();
        log('OB: clearAll: ${box.runtimeType}, removed: $cnt');
      }
    });
    log('OB: clearAll: finished');
  }
}
