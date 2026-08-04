import 'package:flutter/material.dart';

import '../../../design/colors.dart';
import '../../../design/components/lexio_game_summary.dart';
import '../idioms_game.dart';

class IdiomsSummary extends StatelessWidget {
  const IdiomsSummary({
    super.key,
    required this.state,
    required this.onPlayAgain,
    required this.onBack,
  });

  final IdiomsGameState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final reviewItems = <LexioReviewItem>[];
    for (var index = 0; index < state.exercises.length; index++) {
      if (state.results[index] != false) continue;

      final exercise = state.exercises[index];
      final selectedIndex = state.selectedOptionIndices[index];
      if (selectedIndex == null) continue;

      reviewItems.add(
        LexioReviewItem(
          wrongAnswer: exercise.options[selectedIndex],
          correctAnswer: exercise.options[exercise.correctOptionIndex],
          explanation: '„${exercise.expression}” înseamnă ${exercise.meaning}.',
        ),
      );
    }

    return LexioGameSummary(
      gameNumber: '03',
      gameTitle: 'Vorba vine',
      accentColor: LexioColors.teal,
      correctCount: state.correctCount,
      totalCount: state.exercises.length,
      reviewItems: reviewItems,
      onPlayAgain: onPlayAgain,
      onBack: onBack,
    );
  }
}
