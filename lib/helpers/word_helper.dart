import '../models/edited_word.dart';
import '../models/word.dart';
import '../services/exception.dart';
import 'exception.dart';

class WordHelper {
  static String sanitizeUntranslatedWord(String word) {
    final tmpWord = word.trim();
    if (tmpWord.isEmpty) {
      throw ValidationException('Required');
    }
    return tmpWord;
  }

  static List<String> sanitizeTranslations(List<String> translations) {
    final newWordTranslations = <String>[];
    for (int i = 0; i < translations.length; i++) {
      final wordTranslation = translations[i].trim();
      if (wordTranslation.isNotEmpty &&
          newWordTranslations.indexWhere(
                  (x) => x.toLowerCase() == wordTranslation.toLowerCase()) ==
              -1) {
        newWordTranslations.add(wordTranslation);
      }
    }

    if (newWordTranslations.isEmpty) {
      throw ValidationException('Enter at least one translation.');
    }

    return newWordTranslations;
  }

  /// `translations`: keep the ones with latter date.
  ///
  /// `word`: keep the one with latter date.
  ///
  /// `known`: keep value of the newer one
  ///
  /// `acknowledgesCnt`: keep greater value. I guess it would be good to add counts from
  /// `AcknowledgeWord` sync object to firebase value before deciding which one value
  /// should be kept.
  ///
  /// ⚠️`acknowledges` and `acknowledgesToRemove` will be modified if AcknowledgeWord value
  /// will be used.
  static Word mergeWordsWithSameFirebaseId(
    Word firebaseWord,
    Word localWord,
    EditedWord editedWord,
  ) {
    if (firebaseWord.firebaseId != localWord.firebaseId) {
      throw AppException('these are different words',
          'fb word fbId: ${firebaseWord.firebaseId}, local word fbId: ${localWord.firebaseId}');
    }
    late final String word;
    late final List<String> translations;
    final DateTime localWordDate = localWord.lastAcknowledgeAt != null &&
            localWord.lastAcknowledgeAt!.isAfter(editedWord.editedAt)
        ? localWord.lastAcknowledgeAt!
        : editedWord.editedAt;
    final DateTime createAt = firebaseWord.createAt.isBefore(localWord.createAt)
        ? firebaseWord.createAt
        : localWord.createAt;

    // acknowledgesCnt will will be updated when synchronizing acknowledges
    // so there should be no need to do it here.
    final int acknowledgesCnt = firebaseWord.acknowledgesCnt;
    DateTime? lastAcknowledgeAt;
    bool isKnown = false;

    bool isFbAckAtNewer = false;

    // if fb ackAt is greater then local ackAt then use fb value for ackAt
    if (firebaseWord.lastAcknowledgeAt != null &&
        firebaseWord.lastAcknowledgeAt!.isAfter(localWordDate)) {
      lastAcknowledgeAt = firebaseWord.lastAcknowledgeAt;
      isFbAckAtNewer = true;
    } else {
      lastAcknowledgeAt =
          localWord.lastAcknowledgeAt ?? firebaseWord.lastAcknowledgeAt;
    }

    // is known
    isKnown = isFbAckAtNewer ? firebaseWord.known : localWord.known;

    word = isFbAckAtNewer ? firebaseWord.word : localWord.word;

    // translations
    translations = mergeTranslations(
      firebaseWord.translations,
      localWord.translations,
      isFbAckAtNewer,
    );

    final mergedWord = Word(
      id: localWord.id,
      firebaseId: localWord.firebaseId,
      firebaseUserId: localWord.firebaseUserId,
      acknowledgesCnt: acknowledgesCnt,
      createAt: createAt,
      known: isKnown,
      lastAcknowledgeAt: lastAcknowledgeAt,
      translations: translations,
      word: word,
      posted: firebaseWord.posted || localWord.posted,
    );

    return mergedWord;
  }

  static List<String> mergeTranslations(List<String> firebaseTranslations,
      List<String> localTranslations, bool isFbAckAtNewer) {
    List<String> translations =
        isFbAckAtNewer ? [...firebaseTranslations] : [...localTranslations];

    return translations;
  }

  static bool valuesEqual(Word w1, Word w2) {
    if (!(w1.word == w2.word &&
        w1.translations.length == w2.translations.length)) {
      return false;
    }

    final trs1 = w1.translations; //.map((e) => e.toLowerCase());
    final trs2 = w2.translations; //.map((e) => e.toLowerCase());

    return trs1.every((t1) => trs2.contains(t1));
  }

  static bool equal(Word w1, Word w2) {
    if (!(w1.word == w2.word &&
        w1.known == w2.known &&
        w1.acknowledgesCnt == w2.acknowledgesCnt &&
        w1.lastAcknowledgeAt == w2.lastAcknowledgeAt &&
        w1.translations.length == w2.translations.length)) {
      return false;
    }

    final trs1 = w1.translations;
    final trs2 = w2.translations;

    return trs1.every((t1) => trs2.contains(t1));
  }

  static bool deepEqual(Word w1, Word w2) {
    return w1.firebaseId == w2.firebaseId &&
        w1.createAt == w2.createAt &&
        equal(w1, w2);
  }

  /// this function differentiate from the `mergeWordsWithSameFirebaseId` because the latter
  /// has additional knowledge about when last time we modified the word locally
  /// 
  /// keep fb word as `w1` and local as w2 if applicable.
  /// 
  /// TODO: verify some merge logic between the two functions to assert both work as similar as possible
  static Word mergeWords(Word w1, Word w2) {
    assert(w1.firebaseId == w2.firebaseId, 'use only for the "same" words');

    bool isW1LastAckLatest;

    if (w2.lastAcknowledgeAt == null) {
      if (w1.lastAcknowledgeAt == null) {
        isW1LastAckLatest = w1.acknowledgesCnt == w2.acknowledgesCnt
            ? w1.createAt.isBefore(w2.createAt)
            : w1.acknowledgesCnt > w2.acknowledgesCnt;
      } else {
        isW1LastAckLatest = true; // w2 null w1 not null - w1 later
      }
    } else {
      if (w1.lastAcknowledgeAt == null) {
        isW1LastAckLatest = false; // w2 not null, w1 null - w2 later
      } else {
        // both dates not null
        if (w1.lastAcknowledgeAt!.isBefore(w1.lastAcknowledgeAt!)) {
          isW1LastAckLatest = true;
        } else if (w1.lastAcknowledgeAt!.isAfter(w2.lastAcknowledgeAt!)) {
          isW1LastAckLatest = false;
        } else {
          // both dates are equal
          if (w1.acknowledgesCnt != w2.acknowledgesCnt) {
            isW1LastAckLatest = w1.acknowledgesCnt > w2.acknowledgesCnt;
          } else {
            if (w1.createAt.isAfter(w2.createAt)) {
              isW1LastAckLatest = false;
            } else {
              // I can think of no other checks, so lets say w1 is latest
              isW1LastAckLatest = true;
            }
          }
        }
      }
    }

    final Word mergedWord = Word(
      id: w1.id == w2.id
          ? w1.id
          : w1.id == 0
              ? w2.id
              : w1.id,
      firebaseId: w1.firebaseId,
      firebaseUserId: w1.firebaseUserId,
      acknowledgesCnt: w1.acknowledgesCnt > w2.acknowledgesCnt
          ? w1.acknowledgesCnt
          : w2.acknowledgesCnt,
      createAt: w1.createAt.isBefore(w2.createAt) ? w1.createAt : w2.createAt,
      known: isW1LastAckLatest ? w1.known : w2.known,
      lastAcknowledgeAt: isW1LastAckLatest
          ? (w1.lastAcknowledgeAt ?? w2.lastAcknowledgeAt)
          : (w2.lastAcknowledgeAt ?? w1.lastAcknowledgeAt),
      translations: mergeTranslations(
          w1.translations, w2.translations, isW1LastAckLatest),
      word: isW1LastAckLatest ? w1.word : w2.word,
      posted: w1.id != 0 ? w1.posted : w2.posted,
    );

    return mergedWord;
  }
}
