import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lang_words/helpers/exception.dart';
import 'package:lang_words/services/exception.dart';
import 'package:lang_words/widgets/helpers/popups.dart';
import 'package:lang_words/widgets/ui/icon_button_square.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../helpers/word_helper.dart';
import '../../models/word.dart';
import '../../services/words_service.dart';
import '../error_text.dart';
import '../inherited/auth_state.dart';
import 'edit_word_translation_row.dart';
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

  final _listViewController = ScrollController();

  int _translationsCreated = 1;
  late final List<FocusNode> _translationFocusNodes;

  final FocusNode _wordFocusNode = FocusNode(debugLabel: 'the_word');

  late final List<TextEditingController> _translationControllers;

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

      if (widget._word!.translations.isNotEmpty) {
        _translationsCreated = widget._word!.translations.length;
      }
    }

    _translationControllers = List.generate(
      _translationsCreated,
      (index) => TextEditingController(
        text: widget._word?.translations[index],
      ),
    );

    _translationFocusNodes = List.generate(
      _translationsCreated,
      (index) => FocusNode(
        debugLabel: 'translation_$index',
      ),
    );

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
                    Row(
                      children: [
                        Flexible(
                          child: TextField(
                            autofocus: true,
                            controller: _wordController,
                            focusNode: _wordFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Enter a word',
                              errorText: _wordError,
                            ),
                            textInputAction: TextInputAction.next,
                            onChanged: (_) {
                              if (_existingWords != null ||
                                  _wordError != null) {
                                // TODO: keep map of words and their duplicates?
                                setState(() {
                                  _existingWords = null;
                                  _wordError = null;
                                });
                              }
                            },
                          ),
                        ),
                        if (_existingWords?.isNotEmpty == true)
                          IconButtonSquare(
                            onTap: () {
                              _openDialogWithExistingWords();
                            },
                            size: 48,
                            icon: const Icon(
                              Icons.remove_red_eye_outlined,
                              color: AppColors.textDark,
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
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
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (_translationsError != null)
                            Positioned(
                              left: -Sizes.paddingSmall,
                              right: -Sizes.paddingSmall,
                              top: -Sizes.paddingSmall,
                              bottom: -Sizes.paddingSmall,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .inputDecorationTheme
                                        .errorBorder!
                                        .borderSide
                                        .color,
                                    width: 5,
                                  ),
                                ),
                              ),
                            ),
                          if (_translationsError != null)
                            Positioned(
                              bottom: -Sizes.paddingSmall - 5 - Sizes.padding,
                              left: Sizes.paddingSmall,
                              child: ErrorText(
                                _translationsError!,
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .caption
                                    ?.fontSize,
                              ),
                            ),
                          ListView.builder(
                            itemCount: _translationControllers.length,
                            controller: _listViewController,
                            itemBuilder: (context, index) {
                              return EditWordTranslationRow(
                                focusNode: _translationFocusNodes[index],
                                controller: _translationControllers[index],
                                isLast:
                                    _translationControllers.length < index + 2,
                                onActionTap: () {
                                  if (_translationControllers.length <
                                      index + 2) {
                                    _addTranslation(index);
                                    return;
                                  }
                                  _removeTranslation(index);
                                },
                                onEditingComplete: () {
                                  if (_translationFocusNodes.length ==
                                      index + 1) {
                                    return _addTranslation(index);
                                  }
                                  _translationFocusNodes[index + 1]
                                      .requestFocus();
                                },
                              );
                            },
                          ),
                        ],
                      ),
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
      if (mounted) {
        controller.dispose();
        focusNode.dispose();
      }
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
      return; // await _openDialogWithExistingWords();
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
    log('WORD TEST FIELD: focus changed: ${_wordFocusNode.hasFocus}');
    if (_wordFocusNode.hasFocus) {
      return;
    }

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
  }

  void _validateExistingWords(String? word) {
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

  Future<void> _openDialogWithExistingWords() {
    if (_existingWords == null || _existingWords!.isEmpty == true) {
      log('_openDialogWithExistingWords called with not duplicates. ${_existingWords?.length}');
      return Future.sync(() {});
    } else if (_existingWords![0].word.toLowerCase() !=
        _wordController.text.toLowerCase()) {
      log('_openDialogWithExistingWords: current word is different then the one from _existingWords: ${_existingWords![0].word} / ${_wordController.text}');
      return Future.sync(() {});
    }

    return PopupsHelper.showSideSlideDialog(
      context: context,
      content: WordDuplicates(items: _existingWords!),
    );
  }
}

class WordDuplicates extends StatelessWidget {
  const WordDuplicates({
    required List<Word> items,
    super.key,
  }) : _items = items;

  final List<Word> _items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageView.builder(
        itemBuilder: (context, index) {
          return WordDuplicateCard(_items[index % _items.length]);
        },
      ),
    );
  }
}

class WordDuplicateCard extends StatelessWidget {
  const WordDuplicateCard(
    this.word, {
    super.key,
  });
  final Word word;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(word.word),
          const Divider(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: word.translations.map((e) => Text(e)).toList(),
          ),
        ],
      ),
    );
  }
}
