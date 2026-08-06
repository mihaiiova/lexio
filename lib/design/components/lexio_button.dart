import 'package:flutter/material.dart';
import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';

enum LexioButtonVariant { primary, secondary, ghost, danger }

enum LexioButtonSize { small, medium, large }

class LexioButton extends StatelessWidget {
  const LexioButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = LexioButtonVariant.primary,
    this.size = LexioButtonSize.large,
    this.icon,
    this.isExpanded = false,
    this.isLoading = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final LexioButtonVariant variant;
  final LexioButtonSize size;
  final IconData? icon;
  final bool isExpanded;
  final bool isLoading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    final Color backgroundColor;
    final Color foregroundColor;
    final Decoration? decoration;

    switch (variant) {
      case LexioButtonVariant.primary:
        backgroundColor = isDisabled
            ? LexioColors.textTertiary
            : LexioColors.primary;
        foregroundColor = LexioColors.textOnPrimary;
        decoration = null;
      case LexioButtonVariant.secondary:
        backgroundColor = LexioColors.surfaceSecondary;
        foregroundColor = isDisabled
            ? LexioColors.textTertiary
            : LexioColors.primary;
        decoration = BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(LexioRadius.lg),
          border: Border.all(color: LexioColors.divider),
        );
      case LexioButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = isDisabled
            ? LexioColors.textTertiary
            : LexioColors.textPrimary;
        decoration = null;
      case LexioButtonVariant.danger:
        backgroundColor = isDisabled
            ? LexioColors.textTertiary
            : LexioColors.error;
        foregroundColor = LexioColors.textOnPrimary;
        decoration = null;
    }

    final EdgeInsets padding;
    final TextStyle textStyle;
    switch (size) {
      case LexioButtonSize.small:
        padding = const EdgeInsets.symmetric(
          horizontal: LexioSpacing.lg,
          vertical: LexioSpacing.sm + 2,
        );
        textStyle = LexioTextStyles.labelMedium;
      case LexioButtonSize.medium:
        padding = const EdgeInsets.symmetric(
          horizontal: LexioSpacing.xl,
          vertical: LexioSpacing.md,
        );
        textStyle = LexioTextStyles.labelLarge.copyWith(fontSize: 15);
      case LexioButtonSize.large:
        padding = const EdgeInsets.symmetric(
          horizontal: LexioSpacing.xl,
          vertical: LexioSpacing.lg,
        );
        textStyle = LexioTextStyles.labelLarge;
    }

    Widget child = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: LexioSpacing.sm),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foregroundColor,
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: LexioSpacing.sm),
            child: Icon(icon, size: textStyle.fontSize! + 2),
          ),
        Flexible(
          child: Text(
            label,
            style: textStyle.copyWith(color: foregroundColor),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (variant == LexioButtonVariant.ghost) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: padding,
          foregroundColor: foregroundColor,
        ),
        child: Semantics(
          label: semanticLabel ?? label,
          button: true,
          child: child,
        ),
      );
    }

    if (variant == LexioButtonVariant.secondary) {
      return Container(
        decoration: decoration,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: padding,
            foregroundColor: foregroundColor,
          ),
          child: Semantics(
            label: semanticLabel ?? label,
            button: true,
            child: child,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: padding,
      ),
      child: Semantics(
        label: semanticLabel ?? label,
        button: true,
        child: child,
      ),
    );
  }
}
