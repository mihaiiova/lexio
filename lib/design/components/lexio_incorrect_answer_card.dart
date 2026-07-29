import 'package:flutter/material.dart';

import '../colors.dart';
import '../radius.dart';
import '../spacing.dart';
import '../typography.dart';
import 'lexio_button.dart';

class LexioIncorrectAnswerCard extends StatelessWidget {
  const LexioIncorrectAnswerCard({
    super.key,
    required this.description,
    required this.onContinue,
    this.subject,
    this.details,
  });

  final String? subject;
  final String description;
  final String? details;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LexioSpacing.lg),
      decoration: BoxDecoration(
        color: LexioColors.errorBackground,
        borderRadius: BorderRadius.circular(LexioRadius.xl),
        border: Border.all(color: LexioColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, color: LexioColors.error),
              const SizedBox(width: LexioSpacing.sm),
              Text(
                'Răspuns greșit',
                style: LexioTextStyles.labelLarge.copyWith(
                  color: LexioColors.error,
                ),
              ),
            ],
          ),
          if (subject != null) ...[
            const SizedBox(height: LexioSpacing.md),
            Text(
              subject!,
              style: LexioTextStyles.headingSmall.copyWith(
                color: LexioColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: LexioSpacing.xs),
          Text(
            description,
            style: LexioTextStyles.bodyMedium.copyWith(
              color: LexioColors.textPrimary,
            ),
          ),
          if (details != null) ...[
            const SizedBox(height: LexioSpacing.sm),
            Text(
              details!,
              style: LexioTextStyles.bodySmall.copyWith(
                color: LexioColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: LexioSpacing.lg),
          LexioButton(
            label: 'Continuă',
            onPressed: onContinue,
            isExpanded: true,
          ),
        ],
      ),
    );
  }
}
