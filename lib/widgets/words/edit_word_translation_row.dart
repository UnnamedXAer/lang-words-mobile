import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../ui/icon_button_square.dart';

class EditWordTranslationRow extends StatelessWidget {
  const EditWordTranslationRow({
    required VoidCallback onActionTap,
    required VoidCallback onEditingComplete,
    required bool isLast,
    required TextEditingController controller,
    required FocusNode focusNode,
    Key? key,
  })  : _onActionTap = onActionTap,
        _onEditingComplete = onEditingComplete,
        _isLast = isLast,
        _controller = controller,
        _focusNode = focusNode,
        super(key: key);

  final FocusNode _focusNode;
  final TextEditingController _controller;
  final VoidCallback _onActionTap;
  final VoidCallback _onEditingComplete;
  final bool _isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: _controller,
              textInputAction: TextInputAction.next,
              onEditingComplete: _onEditingComplete,
            ),
          ),
          IconButtonSquare(
            onTap: _onActionTap,
            size: 48,
            icon: Icon(
              _isLast ? Icons.add : Icons.remove_outlined,
              color: AppColors.textDark,
            ),
          )
        ],
      ),
    );
  }
}
