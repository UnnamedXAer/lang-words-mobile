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
}
