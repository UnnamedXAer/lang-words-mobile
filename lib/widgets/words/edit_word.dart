import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lang_words/helpers/exception.dart';
import 'package:lang_words/services/exception.dart';
import 'package:lang_words/widgets/helpers/popups.dart';
import 'package:lang_words/widgets/words/edit_word_translations.dart';
import 'package:lang_words/widgets/words/edit_word_word.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../helpers/word_helper.dart';
import '../../models/word.dart';
import '../../services/words_service.dart';
import '../inherited/auth_state.dart';
import 'word_list.dart';

typedef WordDuplicates = List<Word>?;

class EditWord extends StatefulWidget {
  const EditWord({Word? word, Key? key})
      : _word = word,
        super(key: key);

  final Word? _word;

  @override
  State<EditWord> createState() => _EditWordState();
}

class _EditWordState extends State<EditWord> {
  final _listViewController = ScrollController();
  final FocusNode _wordFocusNode = FocusNode(debugLabel: 'the_word');
  final _wordController = TextEditingController();
  late List<TextEditingController> _translationControllers;
  late List<FocusNode> _translationFocusNodes;
  late final Map<ShortcutActivator, VoidCallback> _bindings;
  final Map<String, WordDuplicates> _existingWords = {};
  int _translationsCreatedCount = 1;
  AppException? _wordError;
  String? _translationsError;
  bool _loading = false;
  WordDuplicates _currentDuplicates;
  bool _wordDidChangeAfterDuplicatesMerged = true;
  String _prevWordText = '';

  @override
  void initState() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    super.initState();

    if (widget._word != null) {
      // TODO: using empty array we assume that this word is unique but that
      // may not be the case, we should handle it the same when creating a new word
      // or leave it be as long as use didn't change the `word.word`
      _prevWordText = widget._word!.word;
      _existingWords[_prevWordText.toLowerCase()] = [];
      _currentDuplicates = [];
      _wordDidChangeAfterDuplicatesMerged = false;

      _wordController.text = _prevWordText;
    }
    _fillTranslationsControllersAndFocusNodes(widget._word?.translations ?? []);
    _bindings = _getKeyBindings();
    _wordFocusNode.addListener(_wordFieldFocusChangeHandler);
  }

  @override
  void dispose() {
    _wordController.dispose();
    _wordFocusNode.removeListener(_wordFieldFocusChangeHandler);
    _wordFocusNode.dispose();
    _listViewController.dispose();
    for (var i = 0; i < _translationControllers.length; i++) {
      _translationControllers[i].dispose();
      _translationFocusNodes[i].dispose();
    }
    super.dispose();
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: GestureDetector(
          onTap: () {},
          child: Focus(
            onKey: _keyHandler,
            child: AlertDialog(
              contentPadding: EdgeInsets.only(
                left: Sizes.padding,
                right: Sizes.padding,
                top: Sizes.paddingBig,
                bottom: _translationsError == null
                    ? Sizes.paddingSmall
                    : Sizes.paddingSmall +
                        (Theme.of(context).textTheme.caption?.fontSize ?? 0.0),
              ),
              title: Text(widget._word != null ? 'Edit Word' : 'Add Word'),
              content: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 230,
                  maxHeight: 360,
                  maxWidth: 340,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EditWordWord(
                      wordController: _wordController,
                      wordFocusNode: _wordFocusNode,
                      wordError: _wordError?.message,
                      populateExistingTranslations:
                          _currentDuplicates?.isNotEmpty == true
                              ? _populateTranslationPressHandler
                              : null,
                      onChanged: _wordChangeHandler,
                    ),
                    Container(
                      padding: const EdgeInsets.only(
                        top: Sizes.paddingBig,
                        bottom: Sizes.paddingSmall,
                      ),
                      width: double.infinity,
                      child: Text(
                        'Translations',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    EditWordTranslations(
                      listViewController: _listViewController,
                      translationControllers: _translationControllers,
                      translationFocusNodes: _translationFocusNodes,
                      addTranslation: _addTranslation,
                      removeTranslation: _removeTranslation,
                      translationsError: _translationsError,
                    ),
                  ],
                ),
              ),
              actions: [
                Container(
                  constraints: const BoxConstraints(minWidth: 100),
                  margin: const EdgeInsets.only(right: Sizes.paddingBig),
                  child: TextButton(
                    onPressed:
                        _loading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        color: !_loading ? AppColors.reject : null,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 100),
                  child: TextButton(
                    onPressed: _loading ? null : _wordSaveHandler,
                    child: const Text(
                      'SAVE',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addTranslation(int index) {
    setState(() {
      _translationControllers.add(TextEditingController());
      _translationFocusNodes.add(
        FocusNode(debugLabel: 'translation_${++_translationsCreatedCount}'),
      );
    });
    _focusOnLastTranslationField();
  }

  void _focusOnLastTranslationField() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _listViewController.jumpTo(
        _listViewController.position.maxScrollExtent,
      );
      if (FocusManager.instance.primaryFocus != null) {
        FocusManager.instance.primaryFocus!.unfocus();
      }
      _translationFocusNodes.last.requestFocus();
    });
  }

  void _removeTranslation(int index) {
    final controller = _translationControllers[index];
    final focusNode = _translationFocusNodes[index];
    setState(() {
      _translationControllers.removeAt(index);
      _translationFocusNodes.removeAt(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.dispose();
      focusNode.dispose();
    });
  }

  KeyEventResult _keyHandler(node, event) {
    KeyEventResult result = KeyEventResult.ignored;

    final focused = FocusManager.instance.primaryFocus;
    if (focused == null ||
        (focused != _wordFocusNode &&
            !_translationFocusNodes.contains(focused))) {
      return result;
    }

    for (final ShortcutActivator activator in _bindings.keys) {
      if (activator.accepts(event, RawKeyboard.instance)) {
        _bindings[activator]!.call();
        result = KeyEventResult.handled;
      }
    }

    return result;
  }

  void _wordChangeHandler(text) {
    log('text: $text, ctrl.text: ${_wordController.text}');

    if (_prevWordText != text) {
      _prevWordText = text;
      _wordDidChangeAfterDuplicatesMerged = true;

      log('setting  word change to true');
      if (_currentDuplicates != null) {
        setState(() {
          _currentDuplicates = null;
        });
      }
    }
  }

  void _wordSaveHandler() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final String? uid = AuthInfo.of(context).uid;
    String? word;
    try {
      word = WordHelper.sanitizeUntranslatedWord(_wordController.text);
      _validateAgainstWordDuplicates(word);
      _wordError = null;
    } on DuplicateException catch (ex) {
      _wordError = ex;
    } on ValidationException catch (ex) {
      _wordError = ex;
    }

    final bool canProceed = await _canProceedSaveDueToDuplicates();
    if (!canProceed) {
      return;
    }

    List<String>? translations;
    try {
      translations = WordHelper.sanitizeTranslations(
          _translationControllers.map((x) => x.text).toList());
      _translationsError = null;
    } on ValidationException catch (ex) {
      _translationsError = ex.message;
    }

    if (word == null ||
        translations == null ||
        _wordError != null ||
        _translationsError != null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    _saveWord(uid, word, translations);
  }

  Future<bool> _canProceedSaveDueToDuplicates() async {
    if (_currentDuplicates == null || !_wordDidChangeAfterDuplicatesMerged) {
      return true;
    }

// _wordDidNotChangeAfterDuplicatesMerged
    final int? result = await PopupsHelper.showSideSlideDialogRich<int?>(
      context: context,
      title: 'Duplicates found!',
      content: RichText(
        text: const TextSpan(
          text: 'This word already exists in your list.',
          children: [
            TextSpan(text: '\nYour options:\n'),
            TextSpan(
              text: '1. Back and Cancel current entry or Merge translations\n',
            ),
            TextSpan(
              text:
                  '2. Continue with current state and override previous version',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(1),
          child: const Text('Continue as is'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(0),
          child: const Text('Back'),
        ),
      ],
    );
    if (result == null || result == 0) {
      return false;
    }
    if (result == 1) {
      return true;
    }
    assert(result >= 2);
    return false;
  }

  void _wordFieldFocusChangeHandler() {
    if (_wordFocusNode.hasFocus) {
      return;
    }

    if (_currentDuplicates != null) {
      log('word field blur, validation skipper because word didn\'t change after the translations were populated.');
      return;
    }

    if (!mounted) return;

    try {
      final String word =
          WordHelper.sanitizeUntranslatedWord(_wordController.text);

      _validateAgainstWordDuplicates(word);
      _wordError = null;
    } on DuplicateException catch (ex) {
      _wordError = ex;
    } on ValidationException catch (ex) {
      _existingWords[_wordController.text.toLowerCase().trim()] = null;
      _wordError = ex;
    }

    setState(() {
      debugPrint('🧶 duplicates: $_currentDuplicates');
    });
  }

  void _validateAgainstWordDuplicates(String? word) {
    if (_currentDuplicates != null) {
      return;
    }

    if (word == null) {
      throw ValidationException('Something is wrong, please reopen the form.');
    }
    final lowercasedWord = word.toLowerCase().trim();
    _currentDuplicates = _findWordDuplicates(word);
    _existingWords[lowercasedWord] = _currentDuplicates;

    if (_existingWords[lowercasedWord]?.isNotEmpty == true) {
      throw DuplicateException('Word already exists');
    }
  }

  List<Word>? _findWordDuplicates(String word) {
    if (_existingWords.containsKey(word.toLowerCase())) {
      return _existingWords[word.toLowerCase()];
    }

    if (_wordError != null) {
      return null;
    }

    final String? uid = AuthInfo.of(context).uid;
    final ws = WordsService();
    try {
      return ws.findWordsByValue(
        uid,
        word,
        firebaseIdToIgnore: widget._word?.firebaseId,
      );
    } catch (err) {
      // this should not throw but if for some bizarre reason it will
      // its better to allow to save than permanently block
      // empty array indicates that no duplicates were found

      // reset duplicates to try again next time if applicable;
      _currentDuplicates = null;

      return [];
    }
  }

  Future<void> _saveWord(
    String? uid,
    String word,
    List<String> translations,
  ) async {
    String? failMessage;
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);

    final service = WordsService();
    WordSaveMode? saveOption;
    String newWordId = '';
    try {
      if (_currentDuplicates != null &&
          _currentDuplicates!.isNotEmpty &&
          !_wordDidChangeAfterDuplicatesMerged) {
        final wordToKeep = _mergeWordDuplicates([..._currentDuplicates!]);
        wordToKeep.word = word;
        wordToKeep.translations = translations;

        newWordId = await service.updateFullWord(
          uid: uid,
          updatedWord: wordToKeep,
        );

        List<Future> deletes = [];
        for (var w in _currentDuplicates!) {
          if (w.id != wordToKeep.id) {
            deletes.add(service.deleteWord(uid, w.id, w.firebaseId));
          }
        }
        WordList.resetWordsKey();

        await Future.wait(deletes);
        saveOption = WordSaveMode.wordDuplicateOverridden;
      } else if (widget._word != null) {
        newWordId = await service.updateWord(
          uid: uid,
          firebaseId: widget._word!.firebaseId,
          word: word,
          translations: translations,
        );
        saveOption = WordSaveMode.wordEdited;
      } else {
        newWordId = await service.addWord(uid, word, translations);
        final duration = Duration(
          milliseconds: mounted &&
                  // ignore: use_build_context_synchronously
                  MediaQuery.of(context).size.width >=
                      Sizes.wordsActionsWrapPoint
              ? 500
              : 350,
        );
        WordList.wordsListKey.currentState?.insertItem(
          0,
          duration: duration,
        );
        saveOption = WordSaveMode.wordAdded;
      }
    } on AppException catch (ex) {
      failMessage = ex.message;
    }

    if (failMessage == null) {
      final String snackText;
      switch (saveOption) {
        case WordSaveMode.wordAdded:
          snackText = 'Word added.';
          break;
        case WordSaveMode.wordEdited:
          snackText = newWordId == widget._word?.firebaseId
              ? 'Word updated.'
              : 'Word re-added.';
          break;
        case WordSaveMode.wordDuplicateOverridden:
          snackText = 'Word merged in the duplicate.';
          break;
        case null:
          snackText = 'Word saved.';
      }

      PopupsHelper.showSnackbar(
        context: context,
        backgroundColor: AppColors.success,
        content: Text(snackText),
        scaffoldMessengerState: scaffoldMessenger,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }

    PopupsHelper.showSnackbar(
      context: context,
      backgroundColor: AppColors.error,
      content: Text(failMessage),
      scaffoldMessengerState: scaffoldMessenger,
    );
  }

  Word _mergeWordDuplicates(List<Word> words) {
    if (words.length < 2) {
      return words.first;
    }

    words.sort((a, b) => (a.lastAcknowledgeAt ?? a.createAt)
        .compareTo((b.lastAcknowledgeAt ?? a.createAt)));

    final w = words.removeAt(0);
    w.known = false;

    for (var duplicate in words) {
      w.acknowledgesCnt += duplicate.acknowledgesCnt;
      if (duplicate.createAt.isAfter(w.createAt)) {
        w.createAt = duplicate.createAt;
      }

      if (w.lastAcknowledgeAt != null &&
          (duplicate.lastAcknowledgeAt == null ||
              duplicate.lastAcknowledgeAt!.isAfter(w.lastAcknowledgeAt!))) {
        w.lastAcknowledgeAt = duplicate.lastAcknowledgeAt;
      }
    }
    w.createAt = words.first.createAt;

    return words.first;
  }

  void _populateTranslationPressHandler() {
    final lowercasedWord = _wordController.text.toLowerCase().trim();
    if (_currentDuplicates == null || _currentDuplicates!.isEmpty == true) {
      log('_populateExistingTranslations called with not duplicates. ${_currentDuplicates?.length}');
      setState(() {
        _wordError = null;
      });
      return;
    } else if (_currentDuplicates![0].word.toLowerCase() != lowercasedWord) {
      setState(() {
        _currentDuplicates = null;
        _wordError = null;
      });
      log('_populateExistingTranslations: current word is different then the one from _currentDuplicates: ${_currentDuplicates![0].word} / ${_wordController.text}');
      return;
    }

    _mergeTranslationsAndClearError(_currentDuplicates!);

    PopupsHelper.showSnackbar(
      context: context,
      backgroundColor: AppColors.info,
      durationMS: 1500,
      content: const Text('Translations merged.'),
    );

    _focusOnLastTranslationField();
  }

  void _mergeTranslationsAndClearError(List<Word> duplicates) {
    List<String> translationsUnion = _getTranslationsUnionWithDuplicates(
      duplicates,
    );

    _fillTranslationsControllersAndFocusNodes(translationsUnion);
    setState(() {
      _wordDidChangeAfterDuplicatesMerged = false;
    });
  }

  List<String> _getTranslationsUnionWithDuplicates(List<Word> duplicates) {
    final translationsUnion = _translationControllers
        .map((x) => x.text)
        .where((element) => element.isNotEmpty)
        .toList();

    for (var word in duplicates) {
      for (var tr in word.translations) {
        if (tr.isEmpty ||
            translationsUnion.any((x) => x.toLowerCase() == tr.toLowerCase())) {
          continue;
        }
        translationsUnion.add(tr);
      }
    }
    return translationsUnion;
  }

  void _fillTranslationsControllersAndFocusNodes(List<String> translations) {
    _translationsCreatedCount = translations.length + 1;

    _translationControllers = List.generate(
      _translationsCreatedCount,
      (index) => TextEditingController(
        text: index < translations.length ? translations[index] : '',
      ),
    );

    _translationFocusNodes = List.generate(
      _translationsCreatedCount,
      (index) => FocusNode(
        debugLabel: 'translation_$index',
      ),
    );
  }

  Map<ShortcutActivator, void Function()> _getKeyBindings() {
    return {
      LogicalKeySet(LogicalKeyboardKey.arrowUp): () {
        final idx =
            _translationFocusNodes.indexOf(FocusManager.instance.primaryFocus!);
        if (idx == -1) {
          return;
        }

        if (idx == 0) {
          _wordFocusNode.requestFocus();
        }

        _translationFocusNodes[idx - 1].requestFocus();
      },
      LogicalKeySet(LogicalKeyboardKey.arrowDown): () {
        final primaryFocus = FocusManager.instance.primaryFocus;

        if (primaryFocus == _wordFocusNode) {
          _translationFocusNodes.first.requestFocus();
          return;
        }

        final idx = _translationFocusNodes.indexOf(primaryFocus!);
        if (idx == -1 || _translationFocusNodes.length <= idx + 1) {
          return;
        }

        _translationFocusNodes[idx + 1].requestFocus();
      },
      LogicalKeySet(LogicalKeyboardKey.enter): () {
        if (FocusManager.instance.primaryFocus == _wordFocusNode) {
          _translationFocusNodes.last.requestFocus();
          return;
        }

        final idx =
            _translationFocusNodes.indexOf(FocusManager.instance.primaryFocus!);
        if (idx == -1) {
          return;
        }

        if (_translationFocusNodes.length == idx + 1) {
          _addTranslation(idx);
          return;
        }

        _translationFocusNodes[idx + 1].requestFocus();
      },
    };
  }
}

enum WordSaveMode {
  wordAdded,
  wordEdited,
  wordDuplicateOverridden,
}
