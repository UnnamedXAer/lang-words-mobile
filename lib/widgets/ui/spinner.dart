import 'package:flutter/cupertino.dart';
import 'package:lang_words/constants/colors.dart';

enum SpinnerSize { small, medium, large }

class Spinner extends StatefulWidget {
  const Spinner({
    this.size = SpinnerSize.medium,
    this.showLabel = false,
    Key? key,
  }) : super(key: key);
  final SpinnerSize size;
  final bool showLabel;

  @override
  State<Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<Spinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late final double width;
    double borderWidth = 3;
    double fontSize = 16;

    switch (widget.size) {
      case SpinnerSize.small:
        width = 16;
        borderWidth = 2;
        break;
      case SpinnerSize.medium:
        width = 42;
        fontSize = 22;
        break;
      case SpinnerSize.large:
        width = 64;
        borderWidth = 4;
        fontSize = 28;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RotationTransition(
          alignment: Alignment.center,
          turns: Tween(begin: 0.3, end: 1.3).animate(
            _controller.drive(
              CurveTween(curve: Curves.easeInOut),
            ),
          ),
          child: Container(
            width: width,
            height: width,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary,
                width: borderWidth,
              ),
            ),
          ),
        ),
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text.rich(
              TextSpan(
                text: 'L',
                children: [
                  TextSpan(
                    text: 'OADING...',
                    style: TextStyle(fontSize: fontSize * 0.7),
                  ),
                ],
              ),
              style: TextStyle(fontSize: fontSize, color: AppColors.textDark),
              textAlign: TextAlign.center,
            ),
          )
      ],
    );
  }
}
