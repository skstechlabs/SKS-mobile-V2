import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpiritualBackground extends StatelessWidget {
  final Widget child;

  const SpiritualBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.spiritualGradient,
      ),
      child: child,
    );
  }
}
