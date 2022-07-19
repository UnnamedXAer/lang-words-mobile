import 'package:flutter/material.dart';
import 'package:lang_words/widgets/default_button.dart';

import '../../constants/colors.dart';
import '../../widgets/error_text.dart';
import '../../widgets/scaffold_with_horizontal_scroll_column.dart';
import '../constants/sizes.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  String? _passwordError;
  String? _newPasswordError;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithHorizontalStrollColumn(
      children: [
        const SizedBox(height: 40),
        Text(
          'Change Password',
          style: Theme.of(context).textTheme.headline4,
          maxLines: 1,
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _passwordController,
          maxLines: 1,
          maxLength: 256,
          cursorWidth: 3,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            counterText: ' ',
            labelText: 'Password',
            errorText: _passwordError,
          ),
          onSubmitted: !_loading ? _resetPassword : null,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _newPasswordController,
          maxLines: 1,
          maxLength: 256,
          cursorWidth: 3,
          textInputAction: TextInputAction.send,
          decoration: InputDecoration(
            counterText: ' ',
            labelText: 'New Password',
            errorText: _newPasswordError,
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
                  ? () => _resetPassword(_passwordController.text)
                  : null,
              text: 'Change Password',
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _resetPassword(String emailAddress) async {
    _passwordError =
        _passwordController.text.isEmpty ? 'Password is required' : null;

    _newPasswordError = _newPasswordController.text.length >= 6
        ? null
        : 'Please enter at least 6 characters';

    setState(() {});
    if (_newPasswordError != null || _passwordError != null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        final width = MediaQuery.of(context).size.width;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            width: width >= Sizes.minWidth ? Sizes.minWidth : null,
            margin: width >= Sizes.minWidth
                ? null
                : const EdgeInsets.symmetric(horizontal: Sizes.paddingSmall),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.zero),
            ),
            backgroundColor: AppColors.success,
            content: const Text('Password changed.'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on Exception catch (ex) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = ex.toString();
        _loading = false;
      });
    }
  }
}
