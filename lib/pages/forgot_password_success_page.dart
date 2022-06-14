import 'package:flutter/material.dart';
import 'package:lang_words/widgets/default_button.dart';

import '../constants/colors.dart';
import '../widgets/scaffold_with_horizontal_scroll_column.dart';

class ForgotPasswordSuccessPage extends StatelessWidget {
  const ForgotPasswordSuccessPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailAddress = ModalRoute.of(context)!.settings.arguments as String;

    return ScaffoldWithHorizontalStrollColumn(
      maxWidth: 400,
      children: [
        const SizedBox(height: 40),
        Text(
          'Forgot Password',
          style: Theme.of(context).textTheme.headline4,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 18,
            ),
            children: [
              const TextSpan(
                text: 'Message with further instruction will be sent to ',
              ),
              TextSpan(
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                ),
                text: emailAddress,
              ),
              const TextSpan(text: ' in a few minutes.'),
              const TextSpan(
                text:
                    '\n\nIf you will not see it check the spam folder or verify if provided email address was correct.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        DefaultButton(
          text: 'Back',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
