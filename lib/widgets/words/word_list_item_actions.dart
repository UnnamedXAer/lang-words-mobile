import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../models/word.dart';

import '../ui/icon_button_square.dart';

class WordListItemActions extends StatelessWidget {
  const WordListItemActions({
    Key? key,
    required Word word,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onToggleKnown,
    required VoidCallback onAcknowledge,
    required bool? loading,
  })  : _word = word,
        _onEdit = onEdit,
        _onDelete = onDelete,
        _onToggleKnown = onAcknowledge,
        _onAcknowledge = onAcknowledge,
        _loading = loading,
        super(key: key);

  final Word _word;
  final VoidCallback _onEdit;
  final VoidCallback _onDelete;
  final VoidCallback _onToggleKnown;
  final VoidCallback _onAcknowledge;
  final bool? _loading;

  @override
  Widget build(BuildContext context) {
    final direction = MediaQuery.of(context).size.width > 950
        ? Axis.horizontal
        : Axis.vertical;

    const iconColor = AppColors.textDark;

    return Material(
      type: MaterialType.transparency,
      child: Wrap(
        direction: direction,
        children: [
          IconButtonSquare(
            onTap: _onEdit,
            isLoading: _loading,
            icon: const Icon(
              Icons.edit_note_outlined,
              color: iconColor,
            ),
          ),
          IconButtonSquare(
            onTap: _onDelete,
            isLoading: _loading,
            icon: const Icon(
              Icons.delete_outline,
              color: iconColor,
            ),
          ),
          IconButtonSquare(
            onTap: _onToggleKnown,
            isLoading: _loading,
            icon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.done_all_outlined,
                  color: iconColor,
                ),
                if (_word.known)
                  const Positioned(
                    bottom: 10,
                    right: 10,
                    child: Icon(
                      Icons.close_outlined,
                      color: iconColor,
                      size: 12,
                    ),
                  )
              ],
            ),
          ),
          if (!_word.known)
            IconButtonSquare(
              onTap: _onAcknowledge,
              isLoading: _loading,
              icon: const Icon(
                Icons.done,
                color: iconColor,
              ),
            ),
        ],
      ),
    );
  }
}
