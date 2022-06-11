import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';
import 'package:lang_words/constants/colors.dart';
import 'package:lang_words/widgets/logo_text.dart';

import '../constants/sizes.dart';
import '../widgets/error_text.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool isLogin = true;
  String? error = 'There is no errors yet.';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppColors.bg,
          constraints: const BoxConstraints(maxWidth: 400),
          alignment: Alignment.center,
          margin: const EdgeInsets.all(Sizes.padding),
          padding: const EdgeInsets.all(Sizes.padding),
          child: Container(
            padding: const EdgeInsets.all(Sizes.padding),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
              color: AppColors.bgWorkSection,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoText(),
                  SizedBox(height: 20),
                  const TextField(
                    decoration:
                        InputDecoration(errorText: 'Da that\'s wrong email'),
                  ),
                  SizedBox(height: 20),
                  TextField(),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all(AppColors.textDarker),
                      ),
                      onPressed: () {
                        log('swiching to login/register');
                      },
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
                                text: isLogin ? 'Registration' : 'Login')
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      child: Text(
                        (isLogin ? 'Login' : 'Register').toUpperCase(),
                      ),
                      onPressed: () {
                        log('is login $isLogin');
                      },
                    ),
                  ),
                  if (isLogin)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all(AppColors.textDarker),
                        ),
                        child: const Text('Forgot password?'),
                        onPressed: () {
                          log('forgot password?');
                        },
                      ),
                    ),
                  if (error != null) ErrorText(error!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
