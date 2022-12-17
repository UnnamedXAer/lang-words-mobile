import 'dart:developer';
import 'dart:io';

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

import '../models/words_sync_info.dart';

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

    if (kDebugMode && Platform.isAndroid && Admin.isAvailable()) {
      // TODO: this may cause build problems for flavors but may not
      _instance._admin = Admin(_instance._store);
    }

    return _instance;
  }

  factory ObjectBoxService() {
    return _instance;
  }

  List<Word> findWordsByValue(
    String uid,
    String word, {
    String? firebaseIdToIgnore,
  }) {
    Condition<Word> conditions = Word_.word
        .equals(word, caseSensitive: false)
        .and(Word_.firebaseUserId.equals(uid));

    if (firebaseIdToIgnore != null) {
      conditions =
          conditions.and(Word_.firebaseId.notEquals(firebaseIdToIgnore));
    }

    final query = _wordBox.query(conditions).build();

    final existingWords = query.find();

    query.close();

    return existingWords;
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

    // if (kDebugMode) {
    //   // TODO: remove
    //   words.forEach((element) {
    //     log('${element.word.padRight(13)}\tposted: ${element.posted}\tknown: ${element.known}\tack: ${element.acknowledgesCnt}');
    //   });
    // }

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
    removeAcknowledgedWord(wordId);
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

    return increaseWordAcknowledges(
      uid,
      word.id,
      firebaseId,
      acknowledgedAt,
    );
  }

  Future<int> increaseWordAcknowledges(
    String uid,
    int wordId,
    String firebaseId,
    DateTime acknowledgedAt,
  ) async {
    AcknowledgeWord? acknowledge = _acknowledgedWordBox.get(wordId);

    if (acknowledge != null) {
      acknowledge.count++;
      acknowledge.lastAcknowledgedAt = acknowledgedAt;
    } else {
      acknowledge = AcknowledgeWord(
        id: wordId,
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

  bool removeAcknowledgedWord(int wordId) {
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

  bool removeToggledIsKnownWord(final int toggledWordId) {
    return _toggledIsKnownWordBox.remove(toggledWordId);
  }

  bool removeToggledIsKnownWords(final int wordId) {
    final removed = _toggledIsKnownWordBox.remove(wordId);
    log('--- removeToggledIsKnownWords: $wordId, $removed');
    return removed;
  }

  bool removeEditedWords(final int wordId) {
    final removed = _editedWordBox.remove(wordId);
    log('--- removeEditedWords: $wordId, $removed');
    return removed;
  }

  Future<void> syncWithRemote() async {
    log('🔃 *** synchronizing with remote...');

    final authService = AuthService();

    final uid = authService.appUser?.uid;

    if (uid == null) {
      debugPrint('!!! sync called with null user id - aborted');
      return;
    }

    final syncBox = _store.box<WordsSyncInfo>();
    final syncQuery =
        syncBox.query(WordsSyncInfo_.firebaseUserId.equals(uid)).build();
    WordsSyncInfo? syncInfo = syncQuery.findUnique();
    syncQuery.close();

    if (kDebugMode) {
      print(
          'last sync for user: $uid was at: ${syncInfo?.lastSyncAt ?? '-this is the first sync-'}');
    }

    final ws = WordsService();

    final List<Word> localWords = getAllWords(uid);
    final List<Word> firebaseWords = await ws.firebaseFetchWords(uid);

    await _syncDeletedWords(
      uid: uid,
      ws: ws,
      firebaseWords: firebaseWords,
    );

    await _syncEditedWords(
      uid: uid,
      ws: ws,
      firebaseWords: firebaseWords,
      localWords: localWords,
    );

    await _syncMergerFirebaseWordsIntoLocal(
      uid: uid,
      ws: ws,
      firebaseWords: firebaseWords,
      localWords: localWords,
      lastSyncAt: syncInfo?.lastSyncAt,
    );

    syncInfo = WordsSyncInfo(
      id: syncInfo?.id ?? 0,
      firebaseUserId: uid,
      lastSyncAt: DateTime.now(),
    );

    syncBox.put(syncInfo);

    debugPrint('*** synchronizing with remote - done');
    return;
  }

  void _updateRemoteWordWithAcknowledges({
    required final Word fbWord,
    required final List<AcknowledgeWord> acknowledges,
    required final List<int> acknowledgesToDelete,
    required final List<Word> wordsToUpsertFirebase,
  }) {
    final acknowledgeIdx =
        acknowledges.indexWhere((x) => x.firebaseId == fbWord.firebaseId);
    if (acknowledgeIdx == -1) {
      return;
    }

    final acknowledge = acknowledges[acknowledgeIdx];
    fbWord.acknowledgesCnt += acknowledge.count;
    if (fbWord.lastAcknowledgeAt == null ||
        acknowledge.lastAcknowledgedAt.isAfter(fbWord.lastAcknowledgeAt!)) {
      fbWord.lastAcknowledgeAt = acknowledge.lastAcknowledgedAt;
    }
    acknowledgesToDelete.add(acknowledge.id);

    wordsToUpsertFirebase.add(fbWord);
  }

  void _updateRemoteWordWithToggles({
    required final Word fbWord,
    required final List<ToggledIsKnownWord> toggles,
    required final List<int> togglesToDelete,
    required final List<Word> wordsToUpsertFirebase,
  }) {
    final toggleIdx =
        toggles.indexWhere((x) => x.firebaseId == fbWord.firebaseId);
    if (toggleIdx == -1) {
      return;
    }

    final toggle = toggles[toggleIdx];

    fbWord.known = toggle.isKnown;

    togglesToDelete.add(toggle.id);

    wordsToUpsertFirebase.add(fbWord);
  }

  Future<void> _syncDeletedWords({
    required final String uid,
    required final WordsService ws,
    required final List<Word> firebaseWords,
  }) async {
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
      firebaseWords.removeWhere(
        (element) => element.firebaseId == deletedWord.firebaseId,
      );
    }

    if (deletedWordsToRemove.isNotEmpty) {
      _deletedWordBox.removeMany(deletedWordsToRemove);
    }
  }

  Future<int> _syncEditedWords({
    required String uid,
    required WordsService ws,
    required List<Word> firebaseWords,
    required List<Word> localWords,
  }) async {
    final localEditedWordsQuery =
        _editedWordBox.query(EditedWord_.firebaseUserId.equals(uid)).build();
    final localEditedWords = localEditedWordsQuery.find();
    localEditedWordsQuery.close();

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
        // TODO: there acknowledges for these deleted words won't sync!
        firebaseWords.removeAt(firebaseWordIdx);

        final mergedWord = WordHelper.mergeEditedWordsWithSameFirebaseId(
          firebaseWord,
          word,
          editedWord,
        );

        log('💠 syncEditedWords: mergedWord: ${mergedWord.word}');

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

        // otherwise - word was not posted yet, we will post it to firebase.
      }

      final success = await ws.firebaseUpsertWord(uid, word);
      if (success) {
        editedWordsToRemove.add(editedWord.id);
        word.posted = true;
        wordsToUpsertLocally.add(word);
        localWords.removeAt(localWordsIdx);
        continue;
      }
      fails++;
    }

    if (editedWordsToRemove.isNotEmpty) {
      _editedWordBox.removeMany(editedWordsToRemove);
    }

    if (wordsToUpsertLocally.isNotEmpty) {
      _wordBox.putMany(wordsToUpsertLocally);
    }

    if (wordsToDeleteLocally.isNotEmpty) {
      _wordBox.removeMany(wordsToDeleteLocally);
      _acknowledgedWordBox.removeMany(wordsToDeleteLocally);
      _toggledIsKnownWordBox.removeMany(wordsToDeleteLocally);
    }

    return fails;
  }

  Future<void> _syncMergerFirebaseWordsIntoLocal({
    required String uid,
    required WordsService ws,
    required List<Word> firebaseWords,
    required List<Word> localWords,
    required DateTime? lastSyncAt,
  }) async {
    final List<Word> wordsToUpsertLocally = [];
    final List<int> wordsToDeleteLocally = [];
    final List<Word> wordsToUpsertFirebase = [];
    final List<String> wordsToDeleteFirebase = [];

    final List<AcknowledgeWord> acknowledges = _getAcknowledgesForSync(uid);
    final List<int> acknowledgesToDelete = [];

    final List<ToggledIsKnownWord> toggles = _getTogglesForSync(uid);
    final List<int> togglesToDelete = [];

    if (firebaseWords.isNotEmpty) {
      int idx;
      Word lWord;
      Word fbWord;

      for (fbWord in firebaseWords) {
        _updateRemoteWordWithAcknowledges(
          fbWord: fbWord,
          acknowledges: acknowledges,
          acknowledgesToDelete: acknowledgesToDelete,
          wordsToUpsertFirebase: wordsToUpsertFirebase,
        );

        _updateRemoteWordWithToggles(
          fbWord: fbWord,
          toggles: toggles,
          togglesToDelete: togglesToDelete,
          wordsToUpsertFirebase: wordsToUpsertFirebase,
        );

        idx = localWords.indexWhere((x) => x.firebaseId == fbWord.firebaseId);

        if (idx == -1) {
          wordsToUpsertLocally.add(fbWord);
          continue;
        }

        // Here we will check words equality. If they are the same then just pop it from
        // the localWords list, otherwise merge and update both local and firebase storages.
        lWord = localWords[idx];
        if (WordHelper.equal(fbWord, lWord)) {
          localWords.removeAt(idx);
          continue;
        }

        // words are not equal, we have to merge them and upsert.

        if (lWord.firebaseId != fbWord.firebaseId) {
          log('❗equal words with different firebaseId, fb: ${fbWord.firebaseId}, l: ${lWord.firebaseId}');
          continue;
        }

        Word mergedWord = WordHelper.mergeWords(
          fbWord,
          lWord,
          lastSyncAt,
        );

        print(
            'merged word: ${mergedWord.word}, tr: ${mergedWord.translations}');

        wordsToUpsertLocally.add(mergedWord);
        localWords.removeAt(idx);
        final wordsToUpsertFirebaseIdx = wordsToUpsertFirebase
            .indexWhere((x) => x.firebaseId == mergedWord.firebaseId);
        if (wordsToUpsertFirebaseIdx != -1) {
          wordsToUpsertFirebase[wordsToUpsertFirebaseIdx] = mergedWord;
        } else {
          wordsToUpsertFirebase.add(mergedWord);
        }
      }
    }

    // here we are left with words that are not in the firebase but are present locally
    // if the word was posted to the firebase and is not there anymore it means that it was
    // delete from another device. If word was not `posted` that means it was created
    // here and never made it to the remote (that should not be the case because we sync this kind of words
    // in the `_syncEditedWords` words).
    for (Word localWord in localWords) {
      if (localWord.posted) {
        wordsToDeleteLocally.add(localWord.id);
      } else {
        wordsToUpsertFirebase.add(localWord);
      }
    }

    await _updateRemoteAfterSync(
      uid: uid,
      ws: ws,
      wordsToDeleteFirebase: wordsToDeleteFirebase,
      wordsToUpsertFirebase: wordsToUpsertFirebase,
    );

    _updateLocalAfterSync(
      wordsToDeleteLocally: wordsToDeleteLocally,
      acknowledgesToDelete: acknowledgesToDelete,
      togglesToDelete: togglesToDelete,
      wordsToUpsertLocally: wordsToUpsertLocally,
    );
  }

  Future<void> _updateRemoteAfterSync({
    required String uid,
    required WordsService ws,
    required List<String> wordsToDeleteFirebase,
    required List<Word> wordsToUpsertFirebase,
  }) async {
    bool success = false;
    for (String firebaseId in wordsToDeleteFirebase) {
      success = await ws.firebaseDeleteWord(uid, firebaseId);
      if (!success) {
        debugPrint(
            '_syncMergerFirebaseWordsIntoLocal: delete from firebase word ($firebaseId) failed.');
      }
    }

    for (Word word in wordsToUpsertFirebase) {
      success = await ws.firebaseUpsertWord(uid, word);
      // TODO: Modify local - set posted to `true`
      assert(
        word.posted,
        'word should be `posted` if it was upserted to the remote, word(${word.firebaseId}',
      );

      if (!success) {
        debugPrint(
            '_syncMergerFirebaseWordsIntoLocal: upsert to firebase word (${word.firebaseId}) failed.');
      }
    }
  }

  void _updateLocalAfterSync({
    required List<int> wordsToDeleteLocally,
    required List<int> acknowledgesToDelete,
    required List<int> togglesToDelete,
    required List<Word> wordsToUpsertLocally,
  }) {
    if (wordsToDeleteLocally.isNotEmpty) {
      _wordBox.removeMany(wordsToDeleteLocally);
      acknowledgesToDelete.addAll(wordsToDeleteLocally);
      togglesToDelete.addAll(wordsToDeleteLocally);
    }

    if (acknowledgesToDelete.isNotEmpty) {
      _acknowledgedWordBox.removeMany(acknowledgesToDelete);
    }

    if (togglesToDelete.isNotEmpty) {
      _toggledIsKnownWordBox.removeMany(togglesToDelete);
    }

    if (wordsToUpsertLocally.isNotEmpty) {
      for (Word word in wordsToUpsertLocally) {
        word.posted = true;
      }
      _wordBox.putMany(wordsToUpsertLocally);
    }
  }

  List<AcknowledgeWord> _getAcknowledgesForSync(String uid) {
    final localAcknowledgedWordsQuery = _acknowledgedWordBox
        .query(AcknowledgeWord_.firebaseUserId.equals(uid))
        .build();

    final acknowledges = localAcknowledgedWordsQuery.find();
    localAcknowledgedWordsQuery.close();

    return acknowledges;
  }

  List<ToggledIsKnownWord> _getTogglesForSync(String uid) {
    final localToggledWordsQuery = _toggledIsKnownWordBox
        .query(ToggledIsKnownWord_.firebaseUserId.equals(uid))
        .build();

    final toggles = localToggledWordsQuery.find();
    localToggledWordsQuery.close();
    return toggles;
  }

  bool arePendingSyncs(String uid) {
    final builder = [
      _acknowledgedWordBox.query(AcknowledgeWord_.firebaseUserId.equals(uid)),
      _toggledIsKnownWordBox
          .query(ToggledIsKnownWord_.firebaseUserId.equals(uid)),
      _editedWordBox.query(EditedWord_.firebaseUserId.equals(uid)),
      _deletedWordBox.query(DeletedWord_.firebaseUserId.equals(uid)),
    ];

    bool anyPendingSync = false;
    try {
      for (final QueryBuilder<Object> builder in builder) {
        if (anyPendingSync) {
          break;
        }
        final query = builder.build();
        anyPendingSync = query.count() > 0;
        query.close();
      }
    } catch (err) {
      // not worth to populate error, just return whatever is the current value.
      debugPrint('arePendingSyncs: err: $err');
    }

    return anyPendingSync;
  }

  void clearAll(String uid) {
    debugPrint('*** clearing all local words (user $uid)...');

    final queries = [
      _store
          .box<WordsSyncInfo>()
          .query(WordsSyncInfo_.firebaseUserId.equals(uid))
          .build(),
      _wordBox.query(Word_.firebaseUserId.equals(uid)).build(),
      _editedWordBox.query(EditedWord_.firebaseUserId.equals(uid)).build(),
      _acknowledgedWordBox
          .query(AcknowledgeWord_.firebaseUserId.equals(uid))
          .build(),
      _toggledIsKnownWordBox
          .query(ToggledIsKnownWord_.firebaseUserId.equals(uid))
          .build(),
      _deletedWordBox.query(DeletedWord_.firebaseUserId.equals(uid)).build(),
    ];

    _store.runInTransaction(TxMode.write, () {
      for (Query<Object> query in queries) {
        final cnt = query.remove();
        query.close();
        log('OB: clearAll: ${query.runtimeType}, removed: $cnt');
      }
    });
    debugPrint('*** all local words cleared, user $uid');
  }
}
