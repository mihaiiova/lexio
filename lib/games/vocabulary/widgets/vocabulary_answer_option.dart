import 'package:flutter/material.dart';

import '../../../design/animations.dart';
import '../../../design/colors.dart';
import '../../../design/radius.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';

class VocabularyAnswerOption extends StatelessWidget {
  const VocabularyAnswerOption({
    super.key,
    required this.label,
    required this.onTap,
    this.isCorrect = false,
    this.isDisabled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isCorrect;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          duration: LexioDurations.instant,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.lg,
            vertical: LexioSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isCorrect ? LexioColors.success : LexioColors.surface,
            borderRadius: BorderRadius.circular(LexioRadius.lg),
            border: Border.all(
              color: isCorrect ? LexioColors.success : LexioColors.divider,
              width: LexioSpacing.xxs,
            ),
          ),
          child: Text(
            label,
            style: LexioTextStyles.bodyMedium.copyWith(
              color: isCorrect
                  ? LexioColors.textOnPrimary
                  : LexioColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
