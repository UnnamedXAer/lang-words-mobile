import 'package:lang_words/widgets/words/edit_word.dart';

import '../models/word.dart';
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

  static Word mergeWords(Word firebaseWord, Word localWord, EditWord editWord) {
    late final String word;
    final translations = <String>[];

    late final DateTime createAt =
        firebaseWord.createAt.isBefore(localWord.createAt)
            ? firebaseWord.createAt
            : localWord.createAt;

    late final int acknowledgesCnt;
    DateTime? lastAcknowledgeAt;
    late final bool isKnown;

    bool isFbAckAtNewer = false;

    // if fb ackAt is greater then local ackAt then use fb value for
    // ackAt and isKnown

    if (firebaseWord.lastAcknowledgeAt != null &&
        (localWord.lastAcknowledgeAt == null ||
            localWord.lastAcknowledgeAt!
                .isBefore(firebaseWord.lastAcknowledgeAt!))) {
      lastAcknowledgeAt = firebaseWord.lastAcknowledgeAt;
      isKnown = firebaseWord.known;
      isFbAckAtNewer = true;
    } else {
      // fb is null or
      // last is null or
      // last is before fb
    }

    lastAcknowledgeAt = lastAcknowledgeAt ??
        localWord.lastAcknowledgeAt ??
        firebaseWord.lastAcknowledgeAt;

    // translations: make union
    // word: keep the one with latter modification date if exists in firebase
    // or the one with greater number on acknowledges
    // otherwise merger it with pattern "!: fbWord/obWord"
    // so the user will able to modify it again without loosing data.

    if (firebaseWord.firebaseId == localWord.firebaseId) {
      word = isFbAckAtNewer ? firebaseWord.word : localWord.word;

      // consider checking if there is any acknowledges to synchronize
      // you can then add them to the firebase and use that
      acknowledgesCnt = firebaseWord.acknowledgesCnt > localWord.acknowledgesCnt
          ? firebaseWord.acknowledgesCnt
          : localWord.acknowledgesCnt;

      // translations:
      // If there is a difference, lets say remote has one word more then
      // I do not see a way to surly know whether a word was added on the remote
      // or it was deleted locally, therefor for now we will keep all of them without
      // duplicates.
      translations.addAll(firebaseWord.translations);

      for (var lTr in localWord.translations) {
        final exists =
            translations.any((fbTr) => fbTr.toLowerCase() == lTr.toLowerCase());

        if (!exists) {
          translations.add(lTr);
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

    throw Exception("not implemented yet");
    // return word;
  }
}
