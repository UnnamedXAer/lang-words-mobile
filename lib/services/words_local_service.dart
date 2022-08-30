import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:lang_words/models/acknowledged_word.dart';
import 'package:lang_words/models/deleted_word.dart';
import 'package:lang_words/models/edited_word.dart';
import 'package:lang_words/models/toggled_is_known_word.dart';
import 'package:lang_words/models/word.dart';
import 'package:lang_words/objectbox.g.dart';
import 'package:lang_words/services/auth_service.dart';
import 'package:lang_words/services/words_service.dart';

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
      _instance._admin = Admin(_instance._store);
    }

    return _instance;
  }

  factory ObjectBoxService() {
    return _instance;
  }

  //
  Future saveWord(Word word, String uid) async {
    final id = _wordBox.put(word);

    final editedWordQuery = _editedWordBox
        .query(EditedWord_.firebaseId.equals(word.firebaseId))
        .build();

    final ids = editedWordQuery.findIds();

    editedWordQuery.close();

    final editedWord = EditedWord(
      id: ids.isNotEmpty ? ids.first : 0,
      firebaseId: word.firebaseId,
      firebaseUserId: word.firebaseUserId,
      editedAt: DateTime.now(),
    );

    await _editedWordBox.putAsync(
      editedWord,
      mode: PutMode.put,
    );

    log('id: $id');
  }

  List<Word> getAllWords(String uid) {
    final query = _wordBox.query(Word_.firebaseUserId.equals(uid)).build();
    final words = query.find();
    query.close();
    return words;
  }

  Future<String> deleteWord(String uid, Word word) async {
    await _deletedWordBox.putAsync(DeletedWord(
      id: word.id,
      firebaseId: word.firebaseId,
      firebaseUserId: uid,
    ));

    _removeEditedWords(word.firebaseId);
    _removeAcknowledgeWords(word.firebaseId);
    _removeToggledIsKnownWords(word.firebaseId);

    _wordBox.remove(word.id);
    return word.firebaseId;
  }

  // bool _clearDeletedWords(String firebaseId) {
  //   return _deletedWordBox
  //           .query(DeletedWord_.firebaseId.equals(firebaseId))
  //           .build()
  //           .remove() >
  //       0;
  // }

  Future<String> acknowledgeWord(
      String uid, String firebaseId, DateTime acknowledgedAt) async {
    final wordQuery =
        _wordBox.query(Word_.firebaseId.equals(firebaseId)).build();

    final word = wordQuery.findFirst();
    if (word != null) {
      word.acknowledgesCnt++;
      word.lastAcknowledgeAt = acknowledgedAt;

      await _wordBox.putAsync(word, mode: PutMode.update);
    }

    wordQuery.close();

    final Query<AcknowledgeWord> ackWordQuery = _acknowledgedWordBox
        .query(AcknowledgeWord_.firebaseId.equals(firebaseId))
        .build();

    AcknowledgeWord? acknowledge = ackWordQuery.findFirst();

    if (acknowledge != null) {
      acknowledge.count++;
      acknowledge.lastAcknowledgedAt = acknowledgedAt;
    } else {
      acknowledge = AcknowledgeWord(
        id: 0,
        firebaseId: firebaseId,
        firebaseUserId: uid,
        count: 1,
        lastAcknowledgedAt: acknowledgedAt,
      );
    }

    await _acknowledgedWordBox.putAsync(acknowledge);

    ackWordQuery.close();

    return firebaseId;
  }

  bool _removeAcknowledgeWords(String firebaseId) {
    final query = _acknowledgedWordBox
        .query(AcknowledgeWord_.firebaseId.equals(firebaseId))
        .build();

    final removed = query.remove() > 0;

    query.close();

    return removed;
  }

  Future<String> toggleWordIsKnown(String uid, Word word) async {
    await _toggledIsKnownWordBox.putAsync(ToggledIsKnownWord(
      id: 0,
      firebaseId: word.firebaseId,
      firebaseUserId: uid,
      toggledAt: word.lastAcknowledgeAt!,
      isKnown: word.known,
    ));

    _wordBox.putAsync(word, mode: PutMode.put);

    return word.firebaseId;
  }

  bool _removeToggledIsKnownWords(String firebaseId) {
    final query = _toggledIsKnownWordBox
        .query(ToggledIsKnownWord_.firebaseId.equals(firebaseId))
        .build();

    final removed = query.remove() > 0;

    query.close();

    return removed;
  }

  bool _removeEditedWords(String firebaseId) {
    final query =
        _editedWordBox.query(EditedWord_.firebaseId.equals(firebaseId)).build();

    final removed = query.remove() > 0;

    query.close();

    return removed;
  }

  void syncWithRemote() async {
    final authService = AuthService();
    if (authService.appUser == null) {
      return;
    }
    final ws = WordsService();

    await _syncDeletedWords(authService.appUser!.uid, ws);
    await _syncEditedWords(authService.appUser!.uid, ws);
    await _syncAcknowledgedWords(authService.appUser!.uid, ws);
    await _syncToggledIsKnownWords(authService.appUser!.uid, ws);
  }

  Future<void> _syncDeletedWords(String uid, WordsService ws) async {
    final localDeletedWordsQuery =
        _deletedWordBox.query(DeletedWord_.firebaseUserId.equals(uid)).build();

    final localDeletedWords = localDeletedWordsQuery.find();

    for (var deletedWord in localDeletedWords) {
      await ws.deleteWord(uid, deletedWord.firebaseId);
    }

    localDeletedWordsQuery.remove();

    localDeletedWordsQuery.close();
  }

  Future<void> _syncEditedWords(String uid, WordsService ws) async {
    final localEditedWordsQuery =
        _editedWordBox.query(EditedWord_.firebaseUserId.equals(uid)).build();
    final localEditedWords = localEditedWordsQuery.find();

    for (var editedWord in localEditedWords) {
      final wordQuery = _wordBox
          .query(Word_.firebaseId.equals(editedWord.firebaseId))
          .build();

      final word = wordQuery.find().first;
      wordQuery.close();

      await ws.updateWord(uid: uid, firebaseId: word.firebaseId);
    }

    localEditedWordsQuery.remove();

    localEditedWordsQuery.close();
  }

  Future<void> _syncAcknowledgedWords(String uid, WordsService ws) async {
    final localAcknowledgedWordsQuery = _acknowledgedWordBox
        .query(AcknowledgeWord_.firebaseUserId.equals(uid))
        .build();

    final localAcknowledgedWords = localAcknowledgedWordsQuery.find();
    try {
      for (var acknowledgedWord in localAcknowledgedWords) {
        await ws.firebaseAcknowledgeWord(
          uid,
          acknowledgedWord.firebaseId,
          acknowledgedWord.count,
          acknowledgedWord.lastAcknowledgedAt,
        );
      }
    } catch (err) {
      log('_syncAcknowledgedWords: $err');
    }

    localAcknowledgedWordsQuery.remove();

    localAcknowledgedWordsQuery.close();
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
}
