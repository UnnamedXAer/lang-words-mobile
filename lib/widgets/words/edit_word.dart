import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lang_words/helpers/exception.dart';
import 'package:lang_words/services/exception.dart';
import 'package:lang_words/widgets/helpers/popups.dart';
import 'package:lang_words/widgets/layout/app_drawer.dart';
import 'package:lang_words/widgets/ui/dialog_action_button.dart';
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

class _EditWordState extends State<EditWord> with WidgetsBindingObserver {
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
  late final bool _inEditMode;
  bool _hadKeyboard = true;
  bool _hadKeyboardInResume = true;
  Timer? _hadKeyboardTimer;
  Timer? _resumeFocusTimer;
  AppLifecycleState _appState = AppLifecycleState.resumed;

  bool get _isForeground => _appState == AppLifecycleState.resumed;
  bool get _isMobile => !Platform.isAndroid || !Platform.isIOS;

  @override
  void initState() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      WidgetsBinding.instance.addObserver(this);
    }
    super.initState();

    _inEditMode = widget._word != null;
    if (_inEditMode) {
      _prevWordText = widget._word!.word;
      _wordController.text = _prevWordText;
    }
    _fillTranslationsControllersAndFocusNodes(widget._word?.translations ?? []);
    _bindings = _getKeyBindings();
    _wordFocusNode.addListener(_wordFieldFocusChangeHandler);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted || !_isForeground || !_isMobile) {
      return;
    }

    if (_hadKeyboardTimer?.isActive == true) {
      _hadKeyboardTimer!.cancel();
    }

    final double insetsBottom =
        WidgetsBinding.instance.window.viewInsets.bottom;
    final hadKeyboardOnTimerSchedule = insetsBottom > 0;

    _hadKeyboardTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isForeground) {
        return;
      }
      _hadKeyboardInResume = hadKeyboardOnTimerSchedule;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted || !_isMobile) {
      return;
    }
    _appState = state;

    switch (state) {
      case AppLifecycleState.resumed:
        _appResumeHandler();
        break;
      case AppLifecycleState.inactive:
        _resumeFocusTimer?.cancel();
        break;
      case AppLifecycleState.paused:
        _hadKeyboard = _hadKeyboardInResume;
        break;
      default:
    }
  }

  @override
  void dispose() {
    _resumeFocusTimer?.cancel();
    _hadKeyboardTimer?.cancel();
    _wordController.dispose();
    _wordFocusNode.removeListener(_wordFieldFocusChangeHandler);
    _wordFocusNode.dispose();
    _listViewController.dispose();
    for (var i = 0; i < _translationControllers.length; i++) {
      _translationControllers[i].dispose();
      _translationFocusNodes[i].dispose();
    }
    if (Platform.isAndroid || Platform.isIOS) {
      WidgetsBinding.instance.removeObserver(this);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight
      ]);
    }
    super.dispose();
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
              title: Text(_inEditMode ? 'Edit Word' : 'Add Word'),
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
                DialogActionButton(
                  onPressed:
                      _loading ? null : () => Navigator.of(context).pop(),
                  textColor: !_loading ? AppColors.reject : null,
                  text: 'CANCEL',
                ),
                const SizedBox(
                    width: Sizes.paddingSmall, height: Sizes.paddingSmall),
                DialogActionButton(
                  onPressed: _loading ? null : _wordSaveHandler,
                  text: 'SAVE',
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
      FocusManager.instance.primaryFocus?.unfocus();
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
    if (_prevWordText != text) {
      _prevWordText = text;
      _wordDidChangeAfterDuplicatesMerged = true;

      if (_currentDuplicates != null) {
        setState(() {
          _currentDuplicates = null;
        });
      }
    }
  }

  void _wordSaveHandler() async {
    setState(() {
      _loading = true;
    });
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
      setState(() {
        _loading = false;
      });
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
    if (_currentDuplicates == null ||
        _currentDuplicates!.isEmpty ||
        !_wordDidChangeAfterDuplicatesMerged) {
      return true;
    }

    final s = _currentDuplicates!.length > 1 ? 's' : '';

    final int? result = await PopupsHelper.showSideSlideDialogRich<int?>(
      context: context,
      title: 'Duplicates found!',
      content: RichText(
        textScaleFactor: 1.1,
        text: TextSpan(
          text: _inEditMode
              ? 'This word has duplicate$s'
              : 'This word already exists in your list.',
          children: [
            const TextSpan(text: '\n\nYour options are:\n\n'),
            TextSpan(
              text: '- Continue with current state and drop duplicate$s\n',
            ),
            TextSpan(
              text: _inEditMode
                  ? '- Back, merge the translations or cancel current changes'
                  : '- Back, merge the translations or cancel current entry',
            ),
          ],
        ),
      ),
      actions: [
        DialogActionButton(
          onPressed: () => Navigator.of(context).pop(1),
          text: 'CONTINUE AS IS',
        ),
        const SizedBox(width: Sizes.paddingSmall, height: Sizes.paddingSmall),
        DialogActionButton(
          onPressed: () => Navigator.of(context).pop(0),
          text: 'BACK',
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
      // log('🧶 word: ${_wordController.text}, duplicates: $_currentDuplicates');
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

    if (_currentDuplicates?.isNotEmpty == true) {
      throw DuplicateException(
          'Word duplicate${_currentDuplicates!.length > 1 ? 's' : ''} found');
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
      if (_currentDuplicates != null && _currentDuplicates!.isNotEmpty) {
        final wordToKeep = _mergeWordDuplicates([..._currentDuplicates!]);
        wordToKeep.word = word;
        wordToKeep.translations = translations;

        newWordId = await service.updateFullWord(
          uid: uid,
          updatedWord: wordToKeep,
          insertAtTop: !_inEditMode,
        );

        // cannot run this as long as we do not find a way to delete items
        // we need delete `wordToKeep` from animated list (see below)
        // _animateWordInsertion(wordToKeep.known);

        final List<Word> wordsToDelete = _currentDuplicates!
            .where((x) => x.id != wordToKeep.id)
            .toList(growable: false);

        if (wordsToDelete.isNotEmpty) {
          log('❌ duplicates to delete: ${wordsToDelete.length}, resetting list key...');
          // TODO: `resetKeys` is a workaround for a lack of easy way to call
          // removeItem on a words list.
          // we need to delete duplicates from the animated list if present
          // and also the word to keep if we want to animate it's insertion at the first position
          // as calling `insertItem` increase underlying list length causing exception
          WordList.resetWordsKey();
          await service.deleteWords(
            uid,
            wordsToDelete.map((x) => x.id).toList(),
            wordsToDelete.map((x) => x.firebaseId).toList(),
          );
        }

        saveOption = WordSaveMode.wordDuplicateOverridden;
      } else if (_inEditMode) {
        newWordId = await service.updateWord(
          uid: uid,
          firebaseId: widget._word!.firebaseId,
          word: word,
          translations: translations,
        );
        saveOption = WordSaveMode.wordEdited;
      } else {
        newWordId = await service.addWord(uid, word, translations);
        _animateWordInsertion(false);
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
    if (_inEditMode) {
      // if we are editing word merge the others into that one
      // so to simplify we insert is and then unshift as we would
      // do in else case after the sorting;
      words.insert(0, widget._word!);
    } else {
      words.sort((a, b) => (a.lastAcknowledgeAt ?? a.createAt)
          .compareTo((b.lastAcknowledgeAt ?? a.createAt)));
    }

    if (words.length < 2) {
      return words.first;
    }

    final targetWord = words.removeAt(0);
    targetWord.known = widget._word?.known ?? false;

    for (var duplicate in words) {
      targetWord.acknowledgesCnt += duplicate.acknowledgesCnt;
      if (duplicate.createAt.isBefore(targetWord.createAt)) {
        targetWord.createAt = duplicate.createAt;
      }

      if (targetWord.lastAcknowledgeAt == null ||
          duplicate.lastAcknowledgeAt?.isAfter(targetWord.lastAcknowledgeAt!) ==
              true) {
        targetWord.lastAcknowledgeAt = duplicate.lastAcknowledgeAt;
      }
    }

    return targetWord;
  }

  void _populateTranslationPressHandler() {
    final lowercasedWord = _wordController.text.toLowerCase().trim();
    if (_currentDuplicates == null || _currentDuplicates!.isEmpty == true) {
      debugPrint(
          '_populateExistingTranslations called with not duplicates. ${_currentDuplicates?.length}');
      setState(() {
        _wordError = null;
      });
      return;
    } else if (_currentDuplicates![0].word.toLowerCase() != lowercasedWord) {
      setState(() {
        _currentDuplicates = null;
        _wordError = null;
      });
      debugPrint(
          '_populateExistingTranslations: current word is different then the one from _currentDuplicates: ${_currentDuplicates![0].word} / ${_wordController.text}');
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

  void _animateWordInsertion(bool wordIsKnown) {
    // do not animate when editing word as it will stay at current position
    if (_inEditMode ||
        // let's skip animation for known words
        wordIsKnown ||
        // animate only in not know word list
        AppDrawer.navKey.currentState?.widget.currentIndex != 0) {
      log('🦘 _animateWordInsertion: insertion skipped');
      return;
    }

    final duration = Duration(
      milliseconds: mounted &&
              MediaQuery.of(context).size.width >= Sizes.wordsActionsWrapPoint
          ? 500
          : 350,
    );
    WordList.wordsListKey.currentState?.insertItem(
      0,
      duration: duration,
    );
  }

  void _appResumeHandler() {
    if (!_hadKeyboard || !_isForeground) {
      return;
    }

    final node = FocusManager.instance.primaryFocus;
    if (node != null) {
      _resumeFocusTimer?.cancel();
      _resumeFocusTimer = Timer(const Duration(milliseconds: 100), () {
        if (!mounted) {
          return;
        }

        if (!node.hasFocus || FocusManager.instance.primaryFocus == null) {
          return;
        }

        node.requestFocus();
        _showKeyboardNativeCall();
      });
    }
  }

  Future<dynamic> _showKeyboardNativeCall() {
    try {
      return SystemChannels.textInput.invokeMethod<dynamic>('TextInput.show');
    } catch (err) {
      debugPrint('_showKeyboardNativeCall: showing keyboard: err: $err');
      return Future.value();
    }
  }
}

enum WordSaveMode {
  wordAdded,
  wordEdited,
  wordDuplicateOverridden,
}
