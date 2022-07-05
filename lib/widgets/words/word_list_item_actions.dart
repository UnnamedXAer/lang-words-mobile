import 'package:flutter/material.dart';

import '../../constants/colors.dart';

import '../ui/icon_button_square.dart';

class WordListItemActions extends StatelessWidget {
  const WordListItemActions({
    Key? key,
    required this.known,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleKnown,
    required this.onAcknowledge,
    required this.loading,
  }) : super(key: key);

  final bool known;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleKnown;
  final VoidCallback onAcknowledge;
  final bool? loading;

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
            onTap: onEdit,
            isLoading: loading,
            icon: const Icon(
              Icons.edit_note_outlined,
              color: iconColor,
            ),
          ),
          IconButtonSquare(
            onTap: onDelete,
            isLoading: loading,
            icon: const Icon(
              Icons.delete_outline,
              color: iconColor,
            ),
          ),
          IconButtonSquare(
            onTap: onToggleKnown,
            isLoading: loading,
            icon: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.done_all_outlined,
                  color: iconColor,
                ),
                if (known)
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
          if (!known)
            IconButtonSquare(
              onTap: onAcknowledge,
              isLoading: loading,
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
