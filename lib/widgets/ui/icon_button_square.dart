import 'package:flutter/material.dart';

import 'spinner.dart';

class IconButtonSquare extends StatelessWidget {
  const IconButtonSquare({
    required this.icon,
    this.size = 48,
    this.onTap,
    this.focusNode,
    bool? isLoading,
    Key? key,
  })  : _isLoading = isLoading == true,
        super(key: key);

  final Widget icon;
  final double size;
  final void Function()? onTap;
  final bool _isLoading;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      focusNode: focusNode,
      onTap: _isLoading ? null : onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: _isLoading
            ? const Center(
                child: Spinner(
                size: SpinnerSize.small,
              ))
            : icon,
      ),
    );
  }
}
