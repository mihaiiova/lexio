import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/radius.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';

class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.label,
    required this.isPositive,
    required this.onTap,
    this.isDisabled = false,
  });

  final String label;
  final bool isPositive;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPositive ? LexioColors.greenMuted : LexioColors.redMuted;
    final textColor = isPositive ? LexioColors.green : LexioColors.red;
    final borderColor = isPositive
        ? LexioColors.green.withValues(alpha: 0.4)
        : LexioColors.red.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: LexioSpacing.lg,
          horizontal: LexioSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: isDisabled ? LexioColors.surfaceSecondary : bgColor,
          borderRadius: BorderRadius.circular(LexioRadius.full),
          border: Border(
            bottom: BorderSide(
              color: isDisabled ? LexioColors.divider : borderColor,
              width: 4,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: LexioTextStyles.labelLarge.copyWith(
              color: isDisabled ? LexioColors.textTertiary : textColor,
            ),
          ),
        ),
      ),
    );
  }
}
