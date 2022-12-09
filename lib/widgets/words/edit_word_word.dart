import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';
import 'package:lang_words/widgets/ui/icon_button_square.dart';

class EditWordWord extends StatelessWidget {
  const EditWordWord({
    super.key,
    required wordController,
    required wordFocusNode,
    required wordError,
    required onChanged,
    required populateExistingTranslations,
  })  : _wordController = wordController,
        _wordFocusNode = wordFocusNode,
        _wordError = wordError,
        _onChanged = onChanged,
        _populateExistingTranslations = populateExistingTranslations;

  final TextEditingController _wordController;
  final FocusNode _wordFocusNode;
  final String? _wordError;
  final void Function(String)? _onChanged;
  final void Function()? _populateExistingTranslations;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              onChanged: _onChanged),
        ),
        if (_populateExistingTranslations !=
            null) //_existingWords?.isNotEmpty == true)
          IconButtonSquare(
            onTap: _populateExistingTranslations,
            size: 48,
            icon: const Icon(
              Icons.download_outlined,
              color: AppColors.textDark,
            ),
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }
}
