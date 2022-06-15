import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lang_words/widgets/default_button.dart';
import 'package:lang_words/widgets/scaffold_with_horizontal_scroll_column.dart';

import '../../constants/colors.dart';
import '../../widgets/logo_text.dart';
import '../../widgets/error_text.dart';
import '../words/words_page.dart';
import './forgot_password_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  bool _loading = false;
  bool _isLogin = true;
  bool _isPasswordVisible = false;
  String? _error;
  String? _emailError;
  String? _pwdError;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithHorizontalStrollColumn(
      children: _buildForm(context),
    );
  }

  List<Widget> _buildForm(BuildContext context) {
    return [
      const SizedBox(height: 20),
      const LogoText(),
      const SizedBox(height: 20),
      TextField(
        controller: _emailController,
        maxLines: 1,
        maxLength: 256,
        cursorWidth: 3,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
            counterText: ' ',
            errorText: _emailError,
            labelText: 'Email Address'),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _pwdController,
        maxLines: 1,
        maxLength: 256,
        cursorWidth: 3,
        obscureText: !_isPasswordVisible,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.send,
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(
          counterText: ' ',
          labelText: 'Password',
          errorText: _pwdError,
          suffixIcon: IconButton(
            iconSize: 18,
            icon: Icon(_isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        onSubmitted: (_) => !_loading ? _authenticate() : null,
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () {
            setState(() {
              _isLogin = !_isLogin;
            });
          },
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(AppColors.textDarker),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textDarker,
                decoration: TextDecoration.underline,
              ),
              text: 'Switch to ',
              children: [
                TextSpan(
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    text: _isLogin ? 'Registration' : 'Login')
              ],
            ),
          ),
        ),
      ),
      if (_error != null) ErrorText(_error!),
      Align(
        alignment: Alignment.centerRight,
        child: DefaultButton(
          onPressed: !_loading ? _authenticate : null,
          text: (_isLogin ? 'LOGIN' : 'REGISTER'),
        ),
      ),
      if (_isLogin)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all(AppColors.textDarker),
            ),
            child: const Text('Forgot password?'),
            onPressed: () {
              Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const ForgotPasswordPage(),
                ),
              );
            },
          ),
        ),
    ];
  }

  Future<void> _authenticate() async {
    if (kDebugMode) {
      if (_isLogin) {
        Navigator.of(context).pushNamed(WordsPage.routeName);
        return;
      }
    }

    final email = _emailController.text.trim();
    final emailRe = RegExp(r'^\S+@(?:\S|\.)+\.\w+$');
    _emailError = emailRe.hasMatch(email) ? null : 'Incorrect Email Address';
    _pwdError = _pwdController.text.length >= 6
        ? null
        : 'Please enter at least 6 characters';

    setState(() {});
    if (_emailError != null || _pwdError != null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _loading = false;
    });
  }
}
