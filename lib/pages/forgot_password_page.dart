import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../widgets/error_text.dart';
import '../widgets/work_section_container.dart';

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
    return Scaffold(
      body: SafeArea(
        child: WorkSectionContainer(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: Sizes.padding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                        counterText: ' ',
                        errorText: _emailError,
                        labelText: 'Email Address'),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ErrorText(_error!),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                      ),
                      TextButton(
                        onPressed: !_loading ? _resetPassword : null,
                        child: const Text(
                          'Reset Password',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
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

    if (mounted) Navigator.pop(context, true);
  }
}
