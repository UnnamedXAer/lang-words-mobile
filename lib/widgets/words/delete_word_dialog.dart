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
          padding: const EdgeInsets.all(Sizes.paddingBig),
          margin: const EdgeInsets.all(Sizes.paddingBig),
          width: 330,
          decoration: BoxDecoration(
            color: AppColors.bgDialog,
            boxShadow: [
              const BoxShadow(
                color: Colors.black26,
                offset: Offset(
                  0.0,
                  3.0,
                ),
                blurRadius: 5.0,
                spreadRadius: 0.0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(.16),
                offset: const Offset(
                  0.0,
                  3.0,
                ),
                blurRadius: 10.0,
                spreadRadius: 0.0,
              ),
            ],
          ),
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
                alignment: Alignment.topLeft,
                children: [
                  Positioned(
                    top: 5,
                    left: 0,
                    right: 0,
                    child: SelectableText(
                      word,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.transparent,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.wavy,
                        decorationColor: AppColors.warning,
                        decorationThickness: 3,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: SelectableText(
                      word,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sizes.paddingBig),
              const FadingSeparator(),
              const SizedBox(height: Sizes.padding),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  runSpacing: Sizes.padding,
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
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
