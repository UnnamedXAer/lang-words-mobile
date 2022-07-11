import 'package:flutter/material.dart';
import 'package:lang_words/routes/routes.dart';

import '../../widgets/logo_text.dart';
import '../../widgets/error_text.dart';
import '../widgets/scaffold_with_horizontal_scroll_column.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithHorizontalStrollColumn(
      children: [
        const SizedBox(height: 20),
        const LogoText(),
        const SizedBox(height: 40),
        const ErrorText(
          'Sorry, page not found.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        TextButton.icon(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              return Navigator.of(context).pop();
            }

            Navigator.of(context).pushReplacementNamed(RoutesUtil.routeAuth);
          },
          icon: const Icon(Icons.arrow_back_outlined),
          label: const Text('Back'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
