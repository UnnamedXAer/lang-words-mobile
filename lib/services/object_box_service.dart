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

  void setWordPosted(Word word) async {
    assert(word.posted, 'word is not posted');

    try {
      await _wordBox.putAsync(word, mode: PutMode.update);
      log('*** word marked as posted (id: ${word.id}): ${word.word}');
    } catch (err) {
      log('⚠️ setWordPosted (id: ${word.id}): err: $err');
    }
  }

  List<Word> getAllWords(String uid) {
    final query = _wordBox.query(Word_.firebaseUserId.equals(uid)).build();
    final words = query.find();

    if (kDebugMode) {
      // TODO: remove
      words.forEach((element) {
        log('${element.word}: ${element.posted}');
      });
    }

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
    final removed = _wordBox.remove(id);
    log('--- _removeWord: $id, $removed');
    return removed;
  }

  bool removeDeletedWords(int wordId) {
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
    final removed = _toggledIsKnownWordBox.remove(wordId);
    log('--- removeToggledIsKnownWords: $wordId, $removed');
    return removed;
  }

  bool removeEditedWords(int wordId) {
    final removed = _editedWordBox.remove(wordId);
    log('--- removeEditedWords: $wordId, $removed');
    return removed;
  }

  Future<void> syncWithRemote() async {
    log('🔃 *** synchronizing with remote...');

    final authService = AuthService();

    final uid = authService.appUser?.uid;

    if (uid == null) {
      debugPrint('!!! sync called with null user id - skipped');
      return;
    }

    final syncBox = _store.box<WordsSyncInfo>();

    final syncQuery =
        syncBox.query(WordsSyncInfo_.firebaseUserId.equals(uid)).build();
    WordsSyncInfo? syncInfo = syncQuery.findUnique();

    if (kDebugMode) {
      print(
          'last sync for user: $uid was at: ${syncInfo?.lastSyncAt ?? '-this is the first sync-'}');
    }

    final ws = WordsService();
    await _syncDeletedWords(authService.appUser!.uid, ws);

    await _syncEditedWords(
      authService.appUser!.uid,
      ws,
    );

    await _syncAcknowledgedWords(authService.appUser!.uid, ws);
    await _syncToggledIsKnownWords(authService.appUser!.uid, ws);

    // ignore: prefer_conditional_assignment
    if (syncInfo == null) {
      syncInfo = WordsSyncInfo(
        id: 0,
        firebaseUserId: uid,
        lastSyncAt: DateTime.now(),
      );
    }

    syncBox.put(syncInfo);

    debugPrint('*** synchronizing with remote - done');
    return;
  }

  Future<void> _syncDeletedWords(String uid, WordsService ws) async {
    final localDeletedWordsQuery =
        _deletedWordBox.query(DeletedWord_.firebaseUserId.equals(uid)).build();

    final localDeletedWords = localDeletedWordsQuery.find();
    localDeletedWordsQuery.close();

    final List<int> deletedWordsToRemove = [];

    for (var deletedWord in localDeletedWords) {
      final success = await ws.firebaseDeleteWord(uid, deletedWord.firebaseId);
      if (!success) {
        if (kDebugMode) {
          print('sync delete of ${deletedWord.firebaseId} failed.');
        }
        continue;
      }

      if (kDebugMode) {
        print('*** sync: deleted ${deletedWord.firebaseId}');
      }
      deletedWordsToRemove.add(deletedWord.id);
    }

    if (deletedWordsToRemove.isNotEmpty) {
      _deletedWordBox.removeMany(deletedWordsToRemove);
    }
  }

  Future<int> _syncEditedWords(String uid, WordsService ws) async {
    final localEditedWordsQuery =
        _editedWordBox.query(EditedWord_.firebaseUserId.equals(uid)).build();
    final localEditedWords = localEditedWordsQuery.find();
    localEditedWordsQuery.close();

    final localWords = _wordBox.getAll();
    final firebaseWords = await ws.firebaseFetchWords(uid);

    int fails = 0;
    final List<int> editedWordsToRemove = [];
    final List<Word> wordsToUpsertLocally = [];
    final List<int> wordsToDeleteLocally = [];

    for (var editedWord in localEditedWords) {
      final int localWordsIdx =
          localWords.indexWhere((x) => x.firebaseId == editedWord.firebaseId);

      final firebaseWordIdx = firebaseWords
          .indexWhere((x) => editedWord.firebaseId == x.firebaseId);

      if (localWordsIdx == -1) {
        editedWordsToRemove.add(editedWord.id);
        log('ℹ️ _syncEditedWords: `EditedWord` exists with firebaseId: ${editedWord.firebaseId}, but no matching word found in local words - cleared and skipped.');
        continue;
      }

      Word word = localWords[localWordsIdx];

      if (firebaseWordIdx != -1) {
        // we got editedWord, localWord and firebaseWord.
        // merge them together.
        final firebaseWord = firebaseWords[firebaseWordIdx];
        firebaseWords.removeAt(firebaseWordIdx);

        final mergedWord = WordHelper.mergeWordsWithSameFirebaseId(
          firebaseWord,
          word,
          editedWord,
        );

        log('💠 mergedWord: ${mergedWord.word}');

        word = mergedWord;
      } else {
        // we got editedWord and localWord but not firebaseWord.
        // if localWord was posted then we should remove it from localWords,
        // acknowledgedWords and toggledWords (and `continue`)
        if (word.posted) {
          wordsToDeleteLocally.add(word.id);
          editedWordsToRemove.add(editedWord.id);
          localWords.removeAt(localWordsIdx);
          continue;
        }

        // otherwise - words was not posted yet, we will post it to firebase.
      }

      final success = await ws.firebaseUpsertWord(uid, word);
      if (success) {
        editedWordsToRemove.add(editedWord.id);
        word.posted = true;
        wordsToUpsertLocally.add(word);
        continue;
      }
      fails++;
    }

    if (firebaseWords.isNotEmpty) {
      log('👋🏼  ${firebaseWords.length} left.');
      int idx;
      for (var fbWord in firebaseWords) {
        idx = localWords
            .indexWhere((element) => element.firebaseId == fbWord.firebaseId);
        if (idx != -1) {
          localWords.removeAt(idx);
          continue;
        }

        if (fbWord.word.isEmpty) {
          log('❔ firebase word has empty word.');
          // TODO: continue for now as it should not happen, but we would like to remove it
          continue;
        }

        if (fbWord.id != 0) {
          log('❔ why this word has non zero, id: ${fbWord.id}/${fbWord.firebaseId}');
          fbWord.id = 0;
        }
        wordsToUpsertLocally.add(fbWord);
      }
    }

    if (localWords.isNotEmpty) {
      for (var localWord in localWords) {
        if (localWord.posted) {
          wordsToDeleteLocally.add(localWord.id);
          continue;
        }
      }
    }

    if (wordsToDeleteLocally.isNotEmpty) {
      _wordBox.removeMany(wordsToDeleteLocally);
      _acknowledgedWordBox.removeMany(wordsToDeleteLocally);
      _toggledIsKnownWordBox.removeMany(wordsToDeleteLocally);
    }

    if (editedWordsToRemove.isNotEmpty) {
      _editedWordBox.removeMany(editedWordsToRemove);
    }
    if (wordsToUpsertLocally.isNotEmpty) {
      _wordBox.putMany(wordsToUpsertLocally);
    }
    return fails;
  }

  Future<void> _syncAcknowledgedWords(String uid, WordsService ws) async {
    final localAcknowledgedWordsQuery = _acknowledgedWordBox
        .query(AcknowledgeWord_.firebaseUserId.equals(uid))
        .build();

    final localAcknowledgedWords = localAcknowledgedWordsQuery.find();
    localAcknowledgedWordsQuery.close();

    final List<int> acknowledgedWordsToRemove = [];

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
        acknowledgedWordsToRemove.add(acknowledgedWord.id);
        if (kDebugMode) {
          print(
              'synced acknowledges of ${acknowledgedWord.firebaseId} cnt: ${acknowledgedWord.count}');
        }
      }
    } catch (err) {
      log('_syncAcknowledgedWords: $err');
    }

    _acknowledgedWordBox.removeMany(acknowledgedWordsToRemove);
  }

  Future<void> _syncToggledIsKnownWords(String uid, WordsService ws) async {
    final localToggledWordsQuery = _toggledIsKnownWordBox
        .query(ToggledIsKnownWord_.firebaseUserId.equals(uid))
        .build();

    final localToggledWords = localToggledWordsQuery.find();

    List<int> toggledWordsToRemove = [];

    for (var toggledWord in localToggledWords) {
      final word =
          ws.firstWhere((word) => word.firebaseId == toggledWord.firebaseId);

      if (word == null) {
        if (kDebugMode) {
          print(
              '*** sync toggleWordIsKnown: word (${toggledWord.id} / ${toggledWord.firebaseId}) does not exist');
          toggledWordsToRemove.add(toggledWord.id);
          continue;
        }
      }

      final success = await ws.firebaseToggleIsKnown(uid, word!);
      if (!success) {
        if (kDebugMode) {
          print('sync toggle known of ${toggledWord.firebaseId} failed.');
        }
        continue;
      }
      toggledWordsToRemove.add(toggledWord.id);
    }

    _toggledIsKnownWordBox.removeMany(toggledWordsToRemove);
  }

  void clearAll(String uid) {
    debugPrint('*** clearing all local words (user $uid)...');

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
    debugPrint('*** all local words cleared, user $uid');
  }
}
