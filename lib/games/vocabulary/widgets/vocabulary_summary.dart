import 'package:flutter/material.dart';

import '../../../design/colors.dart';
import '../../../design/components/lexio_button.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../vocabulary_content.dart';
import '../vocabulary_game.dart';

class VocabularySummary extends StatelessWidget {
  const VocabularySummary({
    super.key,
    required this.state,
    required this.onPlayAgain,
  });

  final VocabularyGameState state;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final missedExercises = <VocabularyExercise>[
      for (var index = 0; index < state.exercises.length; index++)
        if (state.results[index] == false) state.exercises[index],
    ];
    final percentage = state.exercises.isEmpty
        ? 0
        : (state.correctCount / state.exercises.length * 100).round();

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: LexioSpacing.screenHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: LexioSpacing.xl),
            Text(
              'Runda terminată',
              style: LexioTextStyles.headingLarge.copyWith(
                color: LexioColors.textPrimary,
              ),
            ),
            const SizedBox(height: LexioSpacing.xs),
            Text(
              '${state.correctCount} din ${state.exercises.length} corecte — $percentage%',
              style: LexioTextStyles.bodyLarge.copyWith(
                color: missedExercises.isEmpty
                    ? LexioColors.success
                    : LexioColors.primary,
              ),
            ),
            const SizedBox(height: LexioSpacing.xxxl),
            if (missedExercises.isEmpty)
              Text(
                'Excelent! Ai recunoscut toate sensurile.',
                style: LexioTextStyles.bodyLarge.copyWith(
                  color: LexioColors.success,
                ),
              )
            else ...[
              Text(
                'Cuvinte de repetat (${missedExercises.length})',
                style: LexioTextStyles.labelSmall.copyWith(
                  color: LexioColors.textTertiary,
                ),
              ),
              const SizedBox(height: LexioSpacing.md),
              ...missedExercises.map(_buildMissedExercise),
            ],
            const SizedBox(height: LexioSpacing.xxl),
            LexioButton(
              label: 'Joacă din nou',
              onPressed: onPlayAgain,
              icon: Icons.replay,
              isExpanded: true,
            ),
            const SizedBox(height: LexioSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildMissedExercise(VocabularyExercise exercise) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LexioSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.word,
            style: LexioTextStyles.headingSmall.copyWith(
              color: LexioColors.textPrimary,
            ),
          ),
          const SizedBox(height: LexioSpacing.xs),
          Text(
            exercise.definition,
            style: LexioTextStyles.bodyMedium.copyWith(
              color: LexioColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
