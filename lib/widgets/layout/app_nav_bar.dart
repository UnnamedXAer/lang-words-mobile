import 'package:flutter/material.dart';
import 'package:lang_words/constants/colors.dart';
import 'package:lang_words/services/words_service.dart';

import '../../constants/sizes.dart';
import '../logo_text.dart';
import '../ui/icon_button_square.dart';
import '../words/edit_word.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required bool isMediumScreen,
    required VoidCallback toggleDrawer,
    required String title,
    Key? key,
  })  : _isMediumScreen = isMediumScreen,
        _toggleDrawer = toggleDrawer,
        _title = title,
        super(key: key);

  final bool _isMediumScreen;
  final VoidCallback _toggleDrawer;
  final String _title;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: Container(
        color: AppColors.bgHeader,
        height: kBottomNavigationBarHeight,
        child: Material(
          type: MaterialType.transparency,
          child: Row(
            children: [
              IconButtonSquare(
                onTap: _toggleDrawer,
                size: kBottomNavigationBarHeight,
                icon: const Icon(Icons.menu_outlined),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: Sizes.paddingBig,
                ),
                child: Text(
                  _title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: _isMediumScreen
                    ? Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Sizes.paddingBig,
                        ),
                        child: const LogoText(),
                      )
                    : const SizedBox(),
              ),
              IconButtonSquare(
                onTap: WordsService().fetchWords,
                size: kBottomNavigationBarHeight,
                icon: const Icon(Icons.refresh_outlined),
              ),
              IconButtonSquare(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const EditWord(),
                  );
                },
                size: kBottomNavigationBarHeight,
                icon: const Icon(Icons.add_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
