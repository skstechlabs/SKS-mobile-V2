import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Applies the warm cream background from the design system.
class SpiritualBackground extends StatelessWidget {
  final Widget child;
  const SpiritualBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cream,
      child: child,
    );
  }
}
