import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';
import 'package:lang_words/extensions/date_time.dart';
import 'package:lang_words/services/auth_service.dart';
import 'package:lang_words/services/object_box_service.dart';
import 'package:lang_words/services/words_service.dart';

import '../constants/sizes.dart';
import '../widgets/inherited/auth_state.dart';
import 'change_password_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = AuthInfo.of(context).appUser;
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
                  user?.email ?? ' ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 20),
              _buildDateInfo(
                context,
                'Last login time: ',
                user?.lastLoginTime,
              ),
              const SizedBox(height: 10),
              _buildDateInfo(
                context,
                'Registration time: ',
                user?.registrationTime,
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
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Yes, I\'m sure.'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) {
                      return;
                    }

                    final bs = ObjectBoxService();
                    final authService = AuthService();
                    final ws = WordsService();

                    if (authService.appUser == null) {
                      return;
                    }

                    bs.clearAll(authService.appUser!.uid);
                    ws.clear();
                  },
                  child: const Text('Wipe ALL local words.'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Text _buildDateInfo(BuildContext context, String label, DateTime? date) {
    return Text.rich(
      TextSpan(
        text: label,
        children: [TextSpan(text: date?.format())],
      ),
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.subtitle1,
    );
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
