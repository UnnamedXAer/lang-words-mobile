import 'package:flutter/material.dart';
import 'package:lang_words/constants/sizes.dart';
import 'package:lang_words/widgets/error_text.dart';
import 'package:lang_words/widgets/words/edit_word_translation_row.dart';

class EditWordTranslations extends StatelessWidget {
  const EditWordTranslations({
    super.key,
    required translationsError,
    required translationControllers,
    required translationFocusNodes,
    required listViewController,
    required addTranslation,
    required removeTranslation,
  })  : _translationsError = translationsError,
        _translationControllers = translationControllers,
        _translationFocusNodes = translationFocusNodes,
        _listViewController = listViewController,
        _addTranslation = addTranslation,
        _removeTranslation = removeTranslation;

  final String? _translationsError;
  final List<TextEditingController> _translationControllers;
  final List<FocusNode> _translationFocusNodes;
  final ScrollController _listViewController;
  final void Function(int index) _addTranslation;
  final void Function(int index) _removeTranslation;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
                fontSize: Theme.of(context).textTheme.caption?.fontSize,
              ),
            ),
          ListView.builder(
            itemCount: _translationControllers.length,
            controller: _listViewController,
            itemBuilder: (context, index) {
              return EditWordTranslationRow(
                focusNode: _translationFocusNodes[index],
                controller: _translationControllers[index],
                isLast: _translationControllers.length < index + 2,
                onActionTap: () {
                  if (_translationControllers.length < index + 2) {
                    _addTranslation(index);
                    return;
                  }
                  _removeTranslation(index);
                },
                onEditingComplete: () {
                  if (_translationFocusNodes.length == index + 1) {
                    return _addTranslation(index);
                  }
                  _translationFocusNodes[index + 1].requestFocus();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
