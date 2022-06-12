import 'dart:developer';

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../widgets/logo_text.dart';
import '../constants/sizes.dart';
import '../widgets/error_text.dart';
import '../widgets/work_section_container.dart';
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
    return Scaffold(
      body: SafeArea(
        child: WorkSectionContainer(
          child: _buildForm(context),
        ),
      ),
    );
  }

  Container _buildForm(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: Sizes.padding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  )),
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
                  foregroundColor:
                      MaterialStateProperty.all(AppColors.textDarker),
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
              child: TextButton(
                onPressed: !_loading ? _authenticate : null,
                child: Text(
                  (_isLogin ? 'LOGIN' : 'REGISTER'),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            if (_isLogin)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all(AppColors.textDarker),
                  ),
                  child: const Text('Forgot password?'),
                  onPressed: () async {
                    final sent = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    );
                    log('sent? $sent');
                    if (sent == true && mounted) {
                      late final ScaffoldFeatureController<MaterialBanner,
                          MaterialBannerClosedReason> banner;
                      banner = ScaffoldMessenger.of(context).showMaterialBanner(
                        MaterialBanner(
                          content: const Text(
                              'Check email for further instructions.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                banner.close();
                              },
                              child: const Text('Ok'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _authenticate() async {
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
