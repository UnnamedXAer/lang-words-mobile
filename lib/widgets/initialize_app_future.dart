import 'dart:developer';

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'error_text.dart';
import 'ui/spinner.dart';

class AppInitializationFutureBuilder extends StatefulWidget {
  const AppInitializationFutureBuilder({
    required this.initialize,
    required this.app,
    Key? key,
  }) : super(key: key);

  final Widget app;
  final Future Function() initialize;

  @override
  State<AppInitializationFutureBuilder> createState() =>
      _AppInitializationFutureBuilderState();
}

class _AppInitializationFutureBuilderState
    extends State<AppInitializationFutureBuilder> {
  late final Future _initialization;

  @override
  void initState() {
    super.initState();
    // keep initialization Future object in a variable to
    // prevent calling it on every hot reload
    // which causes lost state in the widget tree below this widget;
    _initialization = widget.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: FutureBuilder(
        future: _initialization,
        builder: (context, initializationSnapshot) {
          log('🔮 FutureBuilder ${initializationSnapshot.connectionState}');

          if (initializationSnapshot.hasError) {
            log('initializationSnapshot.error: ${initializationSnapshot.error}');

            return Center(
              child: Material(
                type: MaterialType.transparency,
                child: ErrorText(
                  'Sorry, unable to initialize app due to:\n${initializationSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (initializationSnapshot.connectionState ==
              ConnectionState.waiting) {
            // TODO: add some logo ect.
            return const Center(
              child: Spinner(
                size: SpinnerSize.large,
              ),
            );
          } else {
            return widget.app;
          }
        },
      ),
    );
  }
}
