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
}


