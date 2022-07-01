import 'package:flutter/material.dart';
import 'package:lang_words/routes/routes.dart';
import 'package:lang_words/widgets/default_button.dart';

import '../../constants/colors.dart';
import '../../widgets/error_text.dart';
import '../../widgets/scaffold_with_horizontal_scroll_column.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithHorizontalStrollColumn(
      children: [
        const SizedBox(height: 40),
        Text(
          'Forgot Password',
          style: Theme.of(context).textTheme.headline4,
          maxLines: 1,
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _emailController,
          maxLines: 1,
          maxLength: 256,
          cursorWidth: 3,
          textInputAction: TextInputAction.send,
          decoration: InputDecoration(
            counterText: ' ',
            errorText: _emailError,
            labelText: 'Email Address',
          ),
          onSubmitted: !_loading ? _resetPassword : null,
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          ErrorText(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 20),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all(AppColors.textDarker),
              ),
              child: const Text('Back'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            DefaultButton(
              onPressed: !_loading
                  ? () => _resetPassword(_emailController.text)
                  : null,
              text: 'Reset Password',
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _resetPassword(String emailAddress) async {
    final email = emailAddress.trim();
    final emailRe = RegExp(r'^\S+@(?:\S|\.)+\.\w+$');
    _emailError = emailRe.hasMatch(email) ? null : 'Incorrect Email Address';

    setState(() {});
    if (_emailError != null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        RoutesUtil.routeAuthForgotPasswordSuccess,
        arguments: email,
      );
    }
  }
}
