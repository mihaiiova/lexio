import 'package:flutter/material.dart';

import '../animations.dart';
import '../colors.dart';
import '../spacing.dart';
import '../radius.dart';
import '../shadows.dart';

class LexioCard extends StatelessWidget {
  const LexioCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.shadows,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: LexioDurations.fast,
      padding: padding ?? const EdgeInsets.all(LexioSpacing.cardPadding),
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: backgroundColor ?? LexioColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(LexioRadius.xl),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: shadows ?? LexioShadows.cardCombined,
      ),
      child: child,
    );

    if (onTap != null) {
      return MergeSemantics(
        child: Semantics(
          button: true,
          child: GestureDetector(onTap: onTap, child: card),
        ),
      );
    }

    return card;
  }
}
