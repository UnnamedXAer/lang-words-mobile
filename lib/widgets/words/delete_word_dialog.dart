import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../ui/fading_separator.dart';

class DeleteDialog extends StatelessWidget {
  const DeleteDialog(
      {required this.onAccept,
      required this.onCancel,
      required this.word,
      Key? key})
      : super(key: key);

  final VoidCallback onAccept;
  final VoidCallback onCancel;
  final String word;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          color: AppColors.bgDialog,
          width: 330,
          padding: const EdgeInsets.all(Sizes.paddingBig),
          margin: const EdgeInsets.all(Sizes.paddingBig),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Delete word',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: Sizes.paddingBig),
              const Text(
                'Are you sure you want to delete word:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topRight,
                children: [
                  Text(
                    word,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 0,
                    child: Text(
                      word,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.transparent,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.wavy,
                        decorationColor: AppColors.warning,
                        decorationThickness: 3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sizes.paddingBig),
              const FadingSeparator(),
              const SizedBox(height: Sizes.padding),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100,
                    child: TextButton(
                      onPressed: onAccept,
                      child: const Text(
                        'YES',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Sizes.paddingBig),
                  SizedBox(
                    width: 100,
                    child: TextButton(
                      onPressed: onCancel,
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          color: AppColors.reject,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
