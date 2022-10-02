import '../models/acknowledged_word.dart';
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

  /// `translations`: make union
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
    final List<String> translations = [];
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

    // translations:
    // If there is a difference, lets say remote has one word more then
    // I do not see a way to surly know whether a word was added on the remote
    // or it was deleted locally, therefor for now we will keep all of them without
    // duplicates.
    translations.addAll(firebaseWord.translations);

    for (var lTr in localWord.translations) {
      final idx = translations
          .indexWhere((fbTr) => fbTr.toLowerCase() == lTr.toLowerCase());

      if (idx == -1) {
        translations.add(lTr);
      } else if (!isFbAckAtNewer) {
        // if in both version the word exists then keep
        // the one with latest 'word date'
        translations[idx] = lTr;
      }
    }

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
    );

    return mergedWord;
  }

  // /// Gets bigger value between remote and local but takes into account not pushed
  // /// acknowledges.
  // static int calculateAcknowledgeCntAndPushAckForRemove(
  //   String firebaseId,
  //   int firebaseAckCnt,
  //   int localAckCnt,
  //   List<AcknowledgeWord> acknowledges,
  //   List<String> acknowledgesToRemove,
  // ) {
  //   int fbCnt = firebaseAckCnt;

  //   for (var i = 0; i < acknowledges.length; i++) {
  //     if (acknowledges[i].firebaseId == firebaseId) {
  //       fbCnt += acknowledges[i].count;
  //       acknowledgesToRemove.add(acknowledges[i].firebaseId);
  //       acknowledges.removeAt(i);
  //       break;
  //     }
  //   }

  //   return fbCnt > localAckCnt ? fbCnt : localAckCnt;
  // }
}
