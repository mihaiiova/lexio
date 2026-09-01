import 'package:flutter/material.dart';

import '../../../design/colors.dart';
import '../../../design/components/lexio_game_summary.dart';
import '../vocabulary_game.dart';

class VocabularySummary extends StatelessWidget {
  const VocabularySummary({
    super.key,
    required this.state,
    required this.onPlayAgain,
    required this.onBack,
    this.discoveredCount,
    this.discoveredTotal,
  });

  final VocabularyGameState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;
  final int? discoveredCount;
  final int? discoveredTotal;

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
          subject: exercise.word,
          wrongAnswer: exercise.options[selectedIndex],
          correctAnswer: exercise.correctOption,
          explanation: exercise.explanation,
        ),
      );
    }

    return LexioGameSummary(
      accentColor: LexioColors.coral,
      correctCount: state.correctCount,
      totalCount: state.exercises.length,
      reviewItems: reviewItems,
      onPlayAgain: onPlayAgain,
      onBack: onBack,
      discoveredCount: discoveredCount,
      discoveredTotal: discoveredTotal,
    );
  }
}
