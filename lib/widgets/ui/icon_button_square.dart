import 'package:flutter/material.dart';

class IconButtonSquare extends StatelessWidget {
  const IconButtonSquare({
    required this.icon,
    this.size = 48,
    this.onTap,
    Key? key,
  }) : super(key: key);

  final Icon icon;
  final double size;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: icon,
      ),
    );
  }
}
