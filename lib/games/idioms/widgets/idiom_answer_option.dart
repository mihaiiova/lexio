import 'package:flutter/material.dart';

import '../../../design/colors.dart';
import '../../../design/radius.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';

class IdiomAnswerOption extends StatelessWidget {
  const IdiomAnswerOption({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.lg,
            vertical: LexioSpacing.md,
          ),
          decoration: BoxDecoration(
            color: LexioColors.surface,
            borderRadius: BorderRadius.circular(LexioRadius.lg),
            border: Border.all(
              color: LexioColors.divider,
              width: LexioSpacing.xxs,
            ),
          ),
          child: Text(
            label,
            style: LexioTextStyles.bodyMedium.copyWith(
              color: LexioColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
