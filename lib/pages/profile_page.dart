import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';
import 'package:lang_words/extensions/date_time.dart';

import '../../widgets/error_text.dart';
import '../constants/sizes.dart';
import '../widgets/ui/spinner.dart';
import 'change_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    Key? key,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final bool _fetching = false;
  final String? _fetchError = null;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      if (_fetching) {
        return const Center(
          child: Spinner(
            size: SpinnerSize.large,
            showLabel: true,
          ),
        );
      }
      if (_fetchError != null) {
        return ErrorText(_fetchError!);
      }
      return Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            height: 170,
            child: Center(
              child: ClipPath(
                clipper: ParallelogramClipper(),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: Sizes.minWidth),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(90),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Sizes.paddingBig),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Profile',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline2,
                ),
                const SizedBox(height: 20),
                FittedBox(
                  clipBehavior: Clip.none,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'test.test..test.test@test.com',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    text: 'Last login time: ',
                    children: [TextSpan(text: DateTime.now().format())],
                  ),
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    text: 'Registration time: ',
                    children: [
                      TextSpan(
                          text: DateTime.now()
                              .subtract(const Duration(days: 3453))
                              .format())
                    ],
                  ),
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage(),
                        ),
                      );
                    },
                    child: const Text('Change Password'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class ParallelogramClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const factor = .33;

    final Path path = Path();
    path.moveTo(0, size.height * factor);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * (1 - factor));
    path.lineTo(0, size.height);
    path.lineTo(0, size.height * factor);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
