import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lang_words/helpers/exception.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../helpers/word_helper.dart';
import '../../models/word.dart';
import '../../services/words_service.dart';
import '../error_text.dart';
import '../inherited/auth_state.dart';
import 'edit_word_translation_row.dart';

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
  }

  @override
  void dispose() {
    _wordController.dispose();
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
                    Padding(
                      padding: const EdgeInsets.only(right: 48),
                      child: TextField(
                        autofocus: true,
                        controller: _wordController,
                        focusNode: _wordFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Enter a word',
                          errorText: _wordError,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        color: AppColors.reject,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 100),
                  child: TextButton(
                    onPressed: _saveWord,
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

  Future<void> _saveWord() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final String? uid = AuthInfo.of(context).uid;
    String? word;
    try {
      word = WordHelper.sanitizeUntranslatedWord(_wordController.text);

      final ws = WordsService();
      if (_wordError == null) {
        final exists = await ws.checkIfWordExists(word, id: widget._word?.id);
        if (exists) {
          throw ValidationException('Word already exists');
        }
      }
      _wordError = null;
    } on ValidationException catch (ex) {
      _wordError = ex.message;
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
      return setState(() {});
    }

    String? failMessage;
    final service = WordsService();
    try {
      String newWordId;
      if (widget._word != null) {
        newWordId = await service.updateWord(
          uid: uid,
          id: widget._word!.id,
          word: word,
          translations: translations,
        );
      } else {
        newWordId = await service.addWord(uid, word, translations);
      }

      if (mounted) {
        final snackText = widget._word == null
            ? 'Word Added.'
            : newWordId == widget._word?.id
                ? 'Word updated'
                : 'Word re-added';

        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackText),
            backgroundColor: AppColors.success,
          ),
        );
      }
      return;
    } on Exception catch (ex) {
      // TODO: remove replace
      failMessage = ex.toString().replaceFirst('Exception: ', '');
    } catch (err) {
      failMessage = 'Something went wrong';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failMessage),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
