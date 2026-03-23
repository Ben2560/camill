import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/camill_colors.dart';

/// テーマ対応カード。
/// Midnightテーマ：BackdropFilter + リキッドグラス風
/// Natural/Classicテーマ：白背景 + 薄い枠線 + 影
class CamillCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const CamillCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = borderRadius ?? BorderRadius.circular(16);

    final content = Padding(padding: padding, child: child);

    if (colors.isDark) {
      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: _CardShell(
            colors: colors,
            radius: radius,
            onTap: onTap,
            child: content,
          ),
        ),
      );
    }

    return _CardShell(
      colors: colors,
      radius: radius,
      onTap: onTap,
      shadow: [
        BoxShadow(
          color: colors.surfaceBorder.withAlpha(60),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      child: content,
    );
  }
}

class _CardShell extends StatelessWidget {
  final CamillColors colors;
  final BorderRadius radius;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;
  final Widget child;

  const _CardShell({
    required this.colors,
    required this.radius,
    required this.child,
    this.onTap,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: radius,
          border: Border.all(color: colors.surfaceBorder),
          boxShadow: shadow,
        ),
        child: child,
      ),
    );
  }
}
