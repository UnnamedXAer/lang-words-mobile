import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';

import '../constants/sizes.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool isLogin = true;

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
      body: Container(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(Sizes.padding),
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          child: Column(
            children: [
              TextField(),
              SizedBox(height: 20),
              TextField(),
              SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: const TextStyle(decoration: TextDecoration.underline),
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
              Container(
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
                TextButton(
                  child: const Text('Forgot password?'),
                  onPressed: () {
                    log('forgot password?');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
