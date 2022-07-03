import 'package:flutter/material.dart';

class IconButtonSquare extends StatelessWidget {
  const IconButtonSquare({
    required this.icon,
    this.size = 48,
    this.onTap,
    this.isLoading = false,
    Key? key,
  }) : super(key: key);

  final Widget icon;
  final double size;
  final void Function()? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: isLoading
            ? const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator.adaptive(),
                ),
              )
            : icon,
      ),
    );
  }
}
