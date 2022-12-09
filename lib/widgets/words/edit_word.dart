import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lang_words/helpers/exception.dart';
import 'package:lang_words/services/exception.dart';
import 'package:lang_words/widgets/words/edit_word_translations.dart';
import 'package:lang_words/widgets/words/edit_word_word.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../helpers/word_helper.dart';
import '../../models/word.dart';
import '../../services/words_service.dart';
import '../inherited/auth_state.dart';
import 'word_list.dart';

class EditWord extends StatefulWidget {
  const EditWord({Word? word, Key? key})
      : _word = word,
        super(key: key);

  final Word? _word;

  @override
  State<EditWord> createState() => _EditWordState();
}

class _EditWordState extends State<EditWord> {
  final _wordController = TextEditingController();
  String? _wordError;
  String? _translationsError;
  bool _loading = false;
  List<Word>? _existingWords = [];
  bool _wordChanged = true;

  final _listViewController = ScrollController();

  int _translationsCreated = 1;
  late List<FocusNode> _translationFocusNodes;

  final FocusNode _wordFocusNode = FocusNode(debugLabel: 'the_word');

  late List<TextEditingController> _translationControllers;

  late final Map<ShortcutActivator, VoidCallback> bindings;

  @override
  void initState() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    super.initState();

    if (widget._word != null) {
      // using empty array we assume that this word is unique but that
      // may not be the case. To handle this case it would require merging and deleting
      // one of them.
      // TODO: Handle case described above.
      _existingWords = [];
      _wordController.text = widget._word!.word;
    }

    _fillTranslations(widget._word?.translations ?? []);

    bindings = {
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

    _wordFocusNode.addListener(_onWordFieldFocusChange);
  }

  void _fillTranslations(List<String> translations) {
    _translationsCreated = translations.length + 1;

    _translationControllers = List.generate(
      _translationsCreated,
      (index) => TextEditingController(
        text: index < translations.length ? translations[index] : '',
      ),
    );

    _translationFocusNodes = List.generate(
      _translationsCreated,
      (index) => FocusNode(
        debugLabel: 'translation_$index',
      ),
    );
  }

  @override
  void dispose() {
    _wordController.dispose();
    _wordFocusNode.removeListener(_onWordFieldFocusChange);
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
            onKey: _onKeyHandler,
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
                      wordError: _wordError,
                      populateExistingTranslations:
                          _existingWords?.isNotEmpty == true
                              ? _populateExistingTranslations
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
                    onPressed: _loading ? null : _onSaveWord,
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
      _translationFocusNodes
          .add(FocusNode(debugLabel: 'translation_${++_translationsCreated}'));
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _listViewController.jumpTo(
        _listViewController.position.maxScrollExtent,
      );
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

  KeyEventResult _onKeyHandler(node, event) {
    KeyEventResult result = KeyEventResult.ignored;

    final focused = FocusManager.instance.primaryFocus;
    if (focused == null ||
        (focused != _wordFocusNode &&
            !_translationFocusNodes.contains(focused))) {
      return result;
    }

    for (final ShortcutActivator activator in bindings.keys) {
      if (activator.accepts(event, RawKeyboard.instance)) {
        bindings[activator]!.call();
        result = KeyEventResult.handled;
      }
    }

    return result;
  }

  void _wordChangeHandler(text) {
    log('text: $text, ctrl.text: ${_wordController.text}');

    if (!_wordChanged || _existingWords != null || _wordError != null) {
      log('setting  word change to true');
      setState(() {
        _wordChanged = true;
        _existingWords = null;
        _wordError = null;
      });
    }
  }

  void _onSaveWord() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final String? uid = AuthInfo.of(context).uid;
    String? word;
    try {
      word = WordHelper.sanitizeUntranslatedWord(_wordController.text);
      _validateExistingWords(word);
      _wordError = null;
    } on DuplicateException catch (ex) {
      _wordError = ex.message;
    } on ValidationException catch (ex) {
      _wordError = ex.message;
    }

    if (_existingWords?.isNotEmpty == true) {
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

  void _onWordFieldFocusChange() {
    if (_wordFocusNode.hasFocus) {
      return;
    }

    if (!_wordChanged) {
      log('word field blur, validation skipper because word didn\'t change.');
      return;
    }

    // TODO: I don't know if it heplps or not, <should profile>.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final String word =
            WordHelper.sanitizeUntranslatedWord(_wordController.text);

        _validateExistingWords(word);
        _wordError = null;
      } on DuplicateException catch (ex) {
        _wordError = ex.message;
      } on ValidationException catch (ex) {
        _existingWords = null;
        _wordError = ex.message;
      }

      log('duplicates: $_existingWords');
      setState(() {});
    });
  }

  void _validateExistingWords(String? word) {
    _wordChanged = false;
    _existingWords = _checkIfWordExist(word);

    if (_existingWords?.isNotEmpty == true) {
      throw DuplicateException('Word already exists');
    }
  }

  List<Word>? _checkIfWordExist(String? word) {
    if (_existingWords != null) {
      return _existingWords;
    }

    if (_wordError != null || word == null) {
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

      // reset word change to try again next time if applicable;
      _wordChanged = true;

      return [];
    }
  }

  Future<void> _saveWord(
      String? uid, String word, List<String> translations) async {
    String? failMessage;
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);
    final service = WordsService();
    try {
      String newWordId;
      if (widget._word != null) {
        newWordId = await service.updateWord(
          uid: uid,
          firebaseId: widget._word!.firebaseId,
          word: word,
          translations: translations,
        );
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
      }

      final snackText = widget._word == null
          ? 'Word Added.'
          : newWordId == widget._word?.firebaseId
              ? 'Word updated'
              : 'Word re-added';

      scaffoldMessenger.hideCurrentMaterialBanner();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(snackText),
          backgroundColor: AppColors.success,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    } on AppException catch (ex) {
      failMessage = ex.message;
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }

    scaffoldMessenger.hideCurrentMaterialBanner();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(failMessage),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _populateExistingTranslations() async {
    if (_existingWords == null || _existingWords!.isEmpty == true) {
      log('_populateExistingTranslations called with not duplicates. ${_existingWords?.length}');
      setState(() {
        _existingWords = null;
        _wordError = null;
      });
      return;
    } else if (_existingWords![0].word.toLowerCase() !=
        _wordController.text.toLowerCase()) {
      setState(() {
        _existingWords = null;
        _wordError = null;
      });
      log('_populateExistingTranslations: current word is different then the one from _existingWords: ${_existingWords![0].word} / ${_wordController.text}');
      return;
    }

    final translationsUnion = _translationControllers
        .map((x) => x.text)
        .where((element) => element.isNotEmpty)
        .toList();

    for (var word in _existingWords!) {
      for (var tr in word.translations) {
        if (tr.isEmpty ||
            translationsUnion.any((x) => x.toLowerCase() == tr.toLowerCase())) {
          continue;
        }
        translationsUnion.add(tr);
      }
    }

    final width = MediaQuery.of(context).size.width;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: width >= Sizes.minWidth ? Sizes.minWidth : null,
        margin: width >= Sizes.minWidth
            ? null
            : const EdgeInsets.symmetric(
                horizontal: Sizes.paddingBig,
                vertical: Sizes.paddingSmall,
              ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.zero),
        ),
        backgroundColor: AppColors.info,
        content: const Text('Translations merged.'),
        duration: const Duration(milliseconds: 1500),
      ),
    );

    setState(() {
      _existingWords = null;
      _wordError = null;
      _fillTranslations(translationsUnion);
    });
    _translationFocusNodes.last.requestFocus();
  }
}
